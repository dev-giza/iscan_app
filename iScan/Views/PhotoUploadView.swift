import SwiftUI
import UIKit

struct PhotoUploadView: View {
    let barcode: String
    @State private var selectedImages: [UIImage] = []
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var showAlert = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // First Slide: Front View
                VStack(spacing: 30) {
                    Text("Лицевая часть")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(15)
                        .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                        .padding(.top, 30)
                    
                    if !selectedImages.isEmpty {
                        Image(uiImage: selectedImages.first!)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 250)
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 20)
                    } else {
                        addPhotoButton
                    }
                    
                    Button(action: {
                        selectedTab = 1
                    }) {
                        Text("Далее")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 20)
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                .tag(0)
                
                // Second Slide: Description
                VStack(spacing: 30) {
                    Text("Описание")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(15)
                        .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                        .padding(.top, 30)
                    
                    if selectedImages.count > 1 {
                        Image(uiImage: selectedImages[1])
                            .resizable()
                            .scaledToFit()
                            .frame(height: 250)
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 20)
                    } else {
                        addPhotoButton
                    }
                    
                    Button(action: uploadPhotos) {
                        Text("Загрузить данные")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(selectedImages.count > 1 ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    .disabled(selectedImages.count <= 1 || isUploading)
                    .padding(.horizontal, 20)
                    
                    if isUploading {
                        ProgressView("Загрузка...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5)
                    }
                    
                    if let error = uploadError {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 20)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                .tag(1)
                
                // Third Slide: Preview
                VStack(spacing: 30) {
                    Text("Предосмотр")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(15)
                        .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                        .padding(.top, 30)
                    
                    // Display preview of the data here
                    Text("Предосмотр данных будет показан здесь.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .alert("Ошибка загрузки", isPresented: $showAlert) {
                Button("ОК", role: .cancel) {}
            } message: {
                Text(uploadError ?? "Произошла неизвестная ошибка")
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImages)
            }
            .sheet(isPresented: $showCamera) {
                CameraView(image: $selectedImages)
            }
        }
    }
    
    private var addPhotoButton: some View {
        HStack(spacing: 20) {
            Button(action: {
                showImagePicker = true
            }) {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    Text("Choose from Library")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.blue)
                }
                .frame(height: 200)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            
            Button(action: {
                showCamera = true
            }) {
                VStack {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    Text("Take Photo")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.blue)
                }
                .frame(height: 200)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.4), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    private func uploadPhotos() {
        guard selectedImages.count > 1 else { return }
        
        isUploading = true
        uploadError = nil
        
        // Ensure the URL is correctly formatted with the barcode as a query parameter
        guard let url = URL(string: "https://iscan.store/update?barcode=\(barcode)") else {
            uploadError = "Invalid URL"
            showAlert = true
            isUploading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Add images
        for (index, image) in selectedImages.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 0.3) {
                print("Adding image data for photo\(index + 1)")
                data.append("--\(boundary)\r\n".data(using: .utf8)!)
                data.append("Content-Disposition: form-data; name=\"images\"; filename=\"photo\(index + 1).jpg\"\r\n".data(using: .utf8)!)
                data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                data.append(imageData)
                data.append("\r\n".data(using: .utf8)!)
            }
        }
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        print("Request data size: \(data.count) bytes")
        
        let task = URLSession.shared.uploadTask(with: request, from: data) { responseData, response, error in
            DispatchQueue.main.async {
                isUploading = false
                
                if let error = error {
                    uploadError = error.localizedDescription
                    showAlert = true
                    print("Upload error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    uploadError = "Invalid response"
                    showAlert = true
                    print("Invalid response")
                    return
                }
                
                print("Response status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    selectedTab = 2 // Move to the third slide
                } else {
                    uploadError = "Upload failed with status code: \(httpResponse.statusCode)"
                    showAlert = true
                }
            }
        }
        
        task.resume()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image.append(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image.append(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
} 