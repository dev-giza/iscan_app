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