import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var productViewModel: ProductViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(productViewModel.scannedProducts) { product in
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        ProductRowView(product: product)
                    }
                }
            }
            .navigationTitle("Scan History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        productViewModel.clearHistory()
                    }) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}

struct ProductRowView: View {
    let product: Product
    
    var body: some View {
        HStack {
            Circle()
                .fill(scoreColor)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading) {
                Text(product.product_name)
                    .font(.headline)
                Text(product.manufacturer)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(product.barcode)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    var scoreColor: Color {
        switch product.score {
        case 0...20: return .red
        case 21...40: return .orange
        case 41...60: return .yellow
        case 61...80: return .green
        default: return .green
        }
    }
} 