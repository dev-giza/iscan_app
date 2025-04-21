import SwiftUI
import UIKit

struct PhotoUploadView: View {
    let barcode: String
    @State private var selectedImages: [UIImage] = []
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var showAlert = false
    @State private var showImagePicker = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Upload Product Photos")
                    .font(.title)
                    .padding()
                
                Text("Please upload 2 photos of the product:")
                    .font(.headline)
                
                if !selectedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(selectedImages, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(10)
                            }
                            
                            if selectedImages.count < 2 {
                                Button(action: {
                                    showImagePicker = true
                                }) {
                                    VStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 50))
                                        Text("Add Photo")
                                    }
                                    .frame(height: 200)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        VStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                            Text("Add Photo")
                        }
                        .frame(height: 200)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                
                if isUploading {
                    ProgressView("Uploading...")
                }
                
                if let error = uploadError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button(action: uploadPhotos) {
                    Text("Upload")
                        .padding()
                        .background(selectedImages.count > 0 ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(selectedImages.isEmpty || isUploading)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Upload Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(uploadError ?? "Unknown error occurred")
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImages)
            }
        }
    }
    
    private func uploadPhotos() {
        guard !selectedImages.isEmpty else { return }
        
        isUploading = true
        uploadError = nil
        
        let url = URL(string: "https://iscan.store/update")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Add barcode
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"barcode\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(barcode)\r\n".data(using: .utf8)!)
        
        // Add images
        for (index, image) in selectedImages.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                data.append("--\(boundary)\r\n".data(using: .utf8)!)
                data.append("Content-Disposition: form-data; name=\"photo\(index + 1)\"; filename=\"photo\(index + 1).jpg\"\r\n".data(using: .utf8)!)
                data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                data.append(imageData)
                data.append("\r\n".data(using: .utf8)!)
            }
        }
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let task = URLSession.shared.uploadTask(with: request, from: data) { responseData, response, error in
            DispatchQueue.main.async {
                isUploading = false
                
                if let error = error {
                    uploadError = error.localizedDescription
                    showAlert = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    uploadError = "Invalid response"
                    showAlert = true
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    dismiss()
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