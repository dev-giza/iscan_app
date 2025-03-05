import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @State private var selectedImageTab = 0
    
    var formattedCategories: [String] {
        product.category.components(separatedBy: ", ")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Product Images
                TabView(selection: $selectedImageTab) {
                    ProductImageView(imageURL: product.image, title: "Product")
                        .tag(0)
                    ProductImageView(imageURL: product.image_ingredients, title: "Ingredients")
                        .tag(1)
                    ProductImageView(imageURL: product.image_nutritions, title: "Nutrition")
                        .tag(2)
                }
                .frame(height: 300)
                .tabViewStyle(PageTabViewStyle())
                
                // Image Navigation
                HStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(selectedImageTab == index ? Color.blue : Color.gray)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.horizontal)
                
                // Product Information
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        // Rating Score Section
                        if let analysis = product.analysis {
                            SectionView(title: "Product Rating") {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("\(analysis.rating_score)")
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(analysis.ratingColor)
                                        Text("/100")
                                            .font(.title2)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text(analysis.rating_description)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    
                                    // Rating Details
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Rating Details:")
                                            .font(.headline)
                                        HStack {
                                            Text("Nutrition:")
                                            Spacer()
                                            Text("\(analysis.rating_details.nutri_score_points)")
                                                .foregroundColor(.green)
                                        }
                                        HStack {
                                            Text("Additives Bonus:")
                                            Spacer()
                                            Text("+\(analysis.rating_details.additives_bonus)")
                                                .foregroundColor(.green)
                                        }
                                        HStack {
                                            Text("NOVA Bonus:")
                                            Spacer()
                                            Text("+\(analysis.rating_details.nova_bonus)")
                                                .foregroundColor(.green)
                                        }
                                        HStack {
                                            Text("Eco Penalty:")
                                            Spacer()
                                            Text("\(analysis.rating_details.eco_penalty)")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .font(.subheadline)
                                }
                            }
                            
                            // Nutrition Section
                            SectionView(title: "Nutrition Facts") {
                                VStack(alignment: .leading, spacing: 8) {
                                    NutritionRow(title: "Energy", value: "\(Int(analysis.energy_kcal)) kcal")
                                    NutritionRow(title: "Proteins", value: "\(String(format: "%.1f", analysis.proteins))g")
                                    NutritionRow(title: "Carbohydrates", value: "\(String(format: "%.1f", analysis.carbohydrates))g")
                                    NutritionRow(title: "Sugars", value: "\(String(format: "%.1f", analysis.sugars))g")
                                    NutritionRow(title: "Fat", value: "\(String(format: "%.1f", analysis.fat))g")
                                    NutritionRow(title: "Saturated Fat", value: "\(String(format: "%.1f", analysis.saturated_fat))g")
                                    NutritionRow(title: "Salt", value: "\(String(format: "%.1f", analysis.salt))g")
                                }
                            }
                            
                            // Labels Section
                            if !analysis.labels.isEmpty {
                                SectionView(title: "Labels") {
                                    SimpleLabelsView(labels: analysis.labels)
                                }
                            }
                        }
                        
                        // Basic Info Section
                        SectionView(title: "Basic Information") {
                            InfoRow(title: "Brand", value: product.brand)
                            InfoRow(title: "Barcode", value: product.barcode)
                            InfoRow(title: "Country", value: product.country)
                        }
                        
                        // Categories Section
                        SectionView(title: "Categories") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(formattedCategories, id: \.self) { category in
                                    HStack {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundColor(.blue)
                                        Text(category)
                                            .font(.body)
                                    }
                                }
                            }
                        }
                        
                        // Ingredients Section
                        SectionView(title: "Ingredients") {
                            Text(product.ingredients.capitalized)
                                .font(.body)
                        }
                        
                        // Additional Info Section
                        SectionView(title: "Additional Information") {
                            InfoRow(title: "Data Source", value: product.creator)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(product.brand)
        .navigationBarTitleDisplayMode(.inline)
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

struct NutritionRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .bold()
        }
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

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.body)
        }
    }
} 
