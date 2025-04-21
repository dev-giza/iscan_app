import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @State private var productImage: UIImage?
    @State private var ingredientsImage: UIImage?
    @State private var isLoadingImages = false
    @State private var imageError: String?
    @State private var selectedTab = 0
    @State private var showContent = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Product Image Section
                ZStack(alignment: .bottom) {
                    if let image = productImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipped()
                    } else if isLoadingImages {
                        ProgressView("Loading images...")
                            .frame(height: 300)
                    }
                    
                    // Product Name and Score Overlay
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(product.product_name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                            
                            Spacer()
                            
                            ScoreCircle(score: product.score)
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    }
                }
                
                // Score Progress Bar
                ScoreProgressBar(score: product.score)
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                // Product Info Tabs
                Picker("Info", selection: $selectedTab) {
                    Text("Продукт").tag(0)
                    Text("Детали").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Tab Content
                Group {
                    switch selectedTab {
                    case 0:
                        ProductTab(product: product, ingredientsImage: ingredientsImage, nutrition: product.nutrition, extra: product.extra)
                    case 1:
                        DetailsTab(product: product, extra: product.extra, ingredientsImage: ingredientsImage)
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.3), value: showContent)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadImages()
            withAnimation {
                showContent = true
            }
        }
    }
    
    private var scoreColor: Color {
        switch product.score {
        case 0...40:
            return .red
        case 41...70:
            return .orange
        case 71...100:
            return .green
        default:
            return .gray
        }
    }
    
    private func loadImages() {
        guard productImage == nil && ingredientsImage == nil else { return }
        
        isLoadingImages = true
        
        if let frontImageURL = product.image_front {
            loadImage(from: frontImageURL) { image in
                productImage = image
                checkLoadingComplete()
            }
        }
        
        if let ingredientsImageURL = product.image_ingredients {
            loadImage(from: ingredientsImageURL) { image in
                ingredientsImage = image
                checkLoadingComplete()
            }
        }
        
        checkLoadingComplete()
    }
    
    private func checkLoadingComplete() {
        if product.image_front == nil && product.image_ingredients == nil {
            isLoadingImages = false
        } else if product.image_front != nil && productImage != nil && 
                  product.image_ingredients != nil && ingredientsImage != nil {
            isLoadingImages = false
        } else if product.image_front != nil && productImage != nil && 
                  product.image_ingredients == nil {
            isLoadingImages = false
        } else if product.image_front == nil && 
                  product.image_ingredients != nil && ingredientsImage != nil {
            isLoadingImages = false
        }
    }
    
    private func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        var finalURLString = urlString
        
        // Если URL начинается с /static/images, добавляем базовый URL
        if urlString.hasPrefix("/static/images") {
            finalURLString = "https://iscan.store\(urlString)"
        }
        
        guard let url = URL(string: finalURLString) else {
            imageError = "Invalid image URL"
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    imageError = error.localizedDescription
                    completion(nil)
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    imageError = "Failed to load image"
                    completion(nil)
                    return
                }
                
                completion(image)
            }
        }.resume()
    }
}

// MARK: - Supporting Views

struct ScoreProgressBar: View {
    let score: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Оценка продукта")
                    .font(.headline)
                Spacer()
                Text("\(score)/100")
                    .font(.headline)
                    .foregroundColor(scoreColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * CGFloat(score) / 100, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 0...40: return .red
        case 41...70: return .orange
        case 71...100: return .green
        default: return .gray
        }
    }
}

struct ScoreCircle: View {
    let score: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(scoreColor)
                .frame(width: 50, height: 50)
            
            Text("\(score)")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 0...40: return .red
        case 41...70: return .orange
        case 71...100: return .green
        default: return .gray
        }
    }
}

struct ProductTab: View {
    let product: Product
    let ingredientsImage: UIImage?
    let nutrition: Nutrition
    let extra: Extra
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Nutrition Section
            VStack(spacing: 20) {
                Text("Пищевая ценность на 100г")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                InfoCard {
                    VStack(spacing: 16) {
                        if let calories = nutrition.calories {
                            NutritionRow(title: "Калории", value: "\(Int(calories)) ккал", icon: "flame.fill", color: .orange)
                        }
                        if let proteins = nutrition.proteins {
                            NutritionRow(title: "Белки", value: "\(String(format: "%.1f", proteins))г", icon: "leaf.fill", color: .green)
                        }
                        if let fats = nutrition.fats {
                            NutritionRow(title: "Жиры", value: "\(String(format: "%.1f", fats))г", icon: "drop.fill", color: .red)
                        }
                        if let carbohydrates = nutrition.carbohydrates {
                            NutritionRow(title: "Углеводы", value: "\(String(format: "%.1f", carbohydrates))г", icon: "circle.grid.2x2.fill", color: .blue)
                        }
                    }
                }
            }
            
            // Allergens Section
            if !product.allergens.isEmpty {
                InfoCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Аллергены")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(allergenIcons(for: product.allergens), id: \.name) { allergen in
                                    VStack(spacing: 8) {
                                        Image(systemName: allergen.icon)
                                            .font(.title2)
                                            .foregroundColor(.red)
                                            .frame(width: 40, height: 40)
                                            .background(Color.red.opacity(0.1))
                                            .clipShape(Circle())
                                        
                                        Text(allergen.name)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            
            // Score Explanation
            if !extra.explanation_score.isEmpty {
                InfoCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Объяснение оценки")
                            .font(.headline)
                        Text(extra.explanation_score)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
    
    private func allergenIcons(for allergens: String) -> [(name: String, icon: String)] {
        let allergenList = allergens.components(separatedBy: ",")
        return allergenList.map { allergen in
            let trimmed = allergen.trimmingCharacters(in: .whitespaces)
            switch trimmed.lowercased() {
            case "молоко", "молочные продукты":
                return (trimmed, "drop.fill")
            case "яйца":
                return (trimmed, "circle.fill")
            case "орехи":
                return (trimmed, "leaf.fill")
            case "глютен", "пшеница":
                return (trimmed, "exclamationmark.triangle.fill")
            case "соя":
                return (trimmed, "leaf.arrow.circlepath")
            case "рыба", "морепродукты":
                return (trimmed, "fish.fill")
            case "арахис":
                return (trimmed, "circle.grid.2x2.fill")
            default:
                return (trimmed, "exclamationmark.triangle.fill")
            }
        }
    }
}

struct DetailsTab: View {
    let product: Product
    let extra: Extra
    let ingredientsImage: UIImage?
    
    var body: some View {
        VStack(spacing: 20) {
            // Product Information
            InfoCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Информация о продукте")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(icon: "barcode", title: "Штрих-код", value: product.barcode)
                        if !product.manufacturer.isEmpty {
                            InfoRow(icon: "building.2", title: "Производитель", value: product.manufacturer)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Ingredients Section
            if !extra.ingredients.isEmpty {
                InfoCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Состав")
                            .font(.headline)
                        Text(extra.ingredients)
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            if let image = ingredientsImage {
                InfoCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Фото состава")
                            .font(.headline)
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // Recommendations Section
            if !extra.recommendedfor.isEmpty || !extra.frequency.isEmpty {
                InfoCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Рекомендации")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            if !extra.recommendedfor.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Рекомендуется для")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text(extra.recommendedfor)
                                        .font(.body)
                                }
                            }
                            
                            if !extra.frequency.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Частота употребления")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text(extra.frequency)
                                        .font(.body)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // Alternatives
            if !extra.alternatives.isEmpty {
                InfoCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Альтернативы")
                            .font(.headline)
                        Text(extra.alternatives)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct InfoCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct NutritionRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

struct SimpleLabelsView: View {
    let labels: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(labels.enumerated()), id: \.element) { index, label in
                if index % 2 == 0 {
                    HStack(spacing: 8) {
                        LabelBadge(text: label)
                        if index + 1 < labels.count {
                            LabelBadge(text: labels[index + 1])
                        }
                    }
                }
            }
        }
    }
}

struct LabelBadge: View {
    let text: String
    
    var body: some View {
        Text(text.replacingOccurrences(of: "-", with: " ").capitalized)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(16)
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)
            
            content
            
            Divider()
        }
    }
}

struct ProductImageView: View {
    let imageURL: String
    let title: String
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure(_):
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 250)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
} 
