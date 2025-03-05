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
            AsyncImage(url: URL(string: product.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 50, height: 50)
            
            VStack(alignment: .leading) {
                Text(product.brand)
                    .font(.headline)
                Text(product.barcode)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
} 