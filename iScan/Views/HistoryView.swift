import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var showAccountInfo = false
    @State private var showHelpInfo = false
    @State private var showScannerIssue = false
    @State private var showBarcodeIssue = false
    @State private var showOtherIssue = false
    @State private var showMissionInfo = false
    @State private var isEditing = false
    
    private func deleteItems(at offsets: IndexSet) {
        productViewModel.scannedProducts.remove(atOffsets: offsets)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(productViewModel.scannedProducts) { product in
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        ProductRowView(product: product)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("История")
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showHelpInfo = true
                        }) {
                            Label("Помощь", systemImage: "questionmark.circle")
                        }
                        
                        Button(action: {
                            showAccountInfo = true
                        }) {
                            Label("Аккаунт", systemImage: "person.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation {
                            isEditing.toggle()
                        }
                    }) {
                        Text(isEditing ? "Готово" : "Изменить")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showAccountInfo) {
                AccountInfoView()
            }
            .sheet(isPresented: $showHelpInfo) {
                HelpInfoView(
                    showAccountInfo: $showAccountInfo,
                    showScannerIssue: $showScannerIssue,
                    showBarcodeIssue: $showBarcodeIssue,
                    showOtherIssue: $showOtherIssue,
                    showMissionInfo: $showMissionInfo
                )
            }
            .sheet(isPresented: $showScannerIssue) {
                ScannerIssueView()
            }
            .sheet(isPresented: $showBarcodeIssue) {
                BarcodeIssueView()
            }
            .sheet(isPresented: $showOtherIssue) {
                OtherIssueView()
            }
            .sheet(isPresented: $showMissionInfo) {
                MissionInfoView()
            }
        }
    }
}

struct ProductRowView: View {
    let product: Product
    @State private var productImage: UIImage?
    
    var body: some View {
        HStack(spacing: 16) {
            // Product Image
            if let image = productImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.product_name)
                    .font(.headline)
                    .lineLimit(1)
                
                if !product.manufacturer.isEmpty {
                    Text(product.manufacturer)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Text(product.barcode)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Score Circle
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(scoreColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text("\(product.score)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(scoreColor)
                }
                
                Text(scoreText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(scoreColor)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            loadImage()
        }
    }
    
    private var scoreText: String {
        switch product.score {
        case 0...40: return "Плохо"
        case 41...60: return "Средне"
        case 61...80: return "Хорошо"
        case 81...100: return "Отлично"
        default: return "Н/Д"
        }
    }
    
    private var scoreColor: Color {
        switch product.score {
        case 0...40: return Color(red: 0.9, green: 0.2, blue: 0.2) // Красный
        case 41...60: return Color(red: 1.0, green: 0.6, blue: 0.0) // Оранжевый
        case 61...80: return Color(red: 0.2, green: 0.8, blue: 0.2) // Зеленый
        case 81...100: return Color(red: 0.0, green: 0.6, blue: 0.0) // Темно-зеленый
        default: return .gray
        }
    }
    
    private func loadImage() {
        guard let imageURL = product.image_front else { return }
        
        var finalURLString = imageURL
        if imageURL.hasPrefix("/static/images") {
            finalURLString = "https://iscan.store\(imageURL)"
        }
        
        guard let url = URL(string: finalURLString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    productImage = image
                }
            }
        }.resume()
    }
}

struct AccountInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Демо версия")
                    .font(.title)
                    .padding()
                
                Text("В данный момент доступна только демо версия приложения. Полная версия с расширенным функционалом появится в ближайшее время.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationBarTitle("Аккаунт", displayMode: .inline)
            .navigationBarItems(trailing: Button("Закрыть") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct HelpInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var showAccountInfo: Bool
    @Binding var showScannerIssue: Bool
    @Binding var showBarcodeIssue: Bool
    @Binding var showOtherIssue: Bool
    @Binding var showMissionInfo: Bool
    @State private var showContactInfo = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Общие проблемы")) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        showScannerIssue = true
                    }) {
                        HStack {
                            Text("Сканер не работает")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        showBarcodeIssue = true
                    }) {
                        HStack {
                            Text("Нет штрих-кода")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        showOtherIssue = true
                    }) {
                        HStack {
                            Text("Другая проблема")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("О проекте")) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        showMissionInfo = true
                    }) {
                        HStack {
                            Text("Наша миссия")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        showContactInfo = true
                    }) {
                        HStack {
                            Text("Связаться с нами")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationBarTitle("Помощь", displayMode: .inline)
            .navigationBarItems(trailing: Button("Закрыть") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showContactInfo) {
                ContactInfoView()
            }
        }
    }
}

struct ContactInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Связаться с нами")
                    .font(.title)
                    .padding()
                
                Text("Мы всегда рады вашим отзывам и предложениям!")
                    .multilineTextAlignment(.center)
                    .padding()
                
                VStack(spacing: 15) {
                    Link(destination: URL(string: "mailto:developer@example.com")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                            Text("Написать разработчику")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Link(destination: URL(string: "https://apps.apple.com/app/your-app-id")!) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.blue)
                            Text("Оставить отзыв в App Store")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitle("Контакты", displayMode: .inline)
            .navigationBarItems(trailing: Button("Закрыть") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ScannerIssueView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Проблемы со сканером")
                    .font(.title)
                    .padding()
                
                Text("Если сканер не работает, попробуйте следующее:\n\n1. Проверьте разрешения камеры в настройках устройства\n2. Перезапустите приложение\n3. Убедитесь, что камера не используется другим приложением\n4. Проверьте, что устройство поддерживает сканирование штрих-кодов")
                    .multilineTextAlignment(.leading)
                    .padding()
                
                Spacer()
            }
            .navigationBarTitle("Сканер не работает", displayMode: .inline)
            .navigationBarItems(trailing: Button("Закрыть") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct BarcodeIssueView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Проблемы со штрих-кодом")
                    .font(.title)
                    .padding()
                
                Text("Если штрих-код не распознается:\n\n1. Убедитесь, что штрих-код четко виден в кадре\n2. Попробуйте изменить угол наклона камеры\n3. Проверьте освещение\n4. Убедитесь, что штрих-код не поврежден")
                    .multilineTextAlignment(.leading)
                    .padding()
                
                Spacer()
            }
            .navigationBarTitle("Нет штрих-кода", displayMode: .inline)
            .navigationBarItems(trailing: Button("Закрыть") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct OtherIssueView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Другие проблемы")
                    .font(.title)
                    .padding()
                
                Text("Если у вас возникла другая проблема:\n\n1. Опишите проблему в отзыве в App Store\n2. Свяжитесь с нами через форму обратной связи\n3. Проверьте наличие обновлений приложения")
                    .multilineTextAlignment(.leading)
                    .padding()
                
                Spacer()
            }
            .navigationBarTitle("Другая проблема", displayMode: .inline)
            .navigationBarItems(trailing: Button("Закрыть") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct MissionInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Наша миссия")
                    .font(.title)
                    .padding()
                
                Text("Мы стремимся сделать мир более здоровым, помогая людям делать осознанный выбор продуктов питания. Наше приложение предоставляет подробную информацию о составе продуктов, их питательной ценности и влиянии на здоровье.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationBarTitle("О проекте", displayMode: .inline)
            .navigationBarItems(trailing: Button("Закрыть") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
} 
