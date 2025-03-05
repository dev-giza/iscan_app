import Foundation
import SwiftUI

class ProductViewModel: ObservableObject {
    @Published var scannedProducts: [Product] = [] {
        didSet {
            saveProducts()
        }
    }
    @Published var currentProduct: Product?
    @Published var isLoading = false
    @Published var error: String?
    @Published var isScanning = true
    @Published var showProductDetail = false {
        didSet {
            if showProductDetail {
                isScanning = false
            }
        }
    }
    
    private let baseURL = "https://iscan.store/api/v1/products/"
    private var isProcessingBarcode = false
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    init() {
        encoder.outputFormatting = .prettyPrinted
        loadProducts()
    }
    
    private var productsFileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("scannedProducts.json")
    }
    
    private func saveProducts() {
        do {
            let data = try encoder.encode(scannedProducts)
            try data.write(to: productsFileURL)
        } catch {
            print("Error saving products: \(error)")
        }
    }
    
    private func loadProducts() {
        do {
            guard FileManager.default.fileExists(atPath: productsFileURL.path) else { return }
            let data = try Data(contentsOf: productsFileURL)
            scannedProducts = try decoder.decode([Product].self, from: data)
        } catch {
            print("Error loading products: \(error)")
        }
    }
    
    func fetchProduct(barcode: String) async {
        guard !isProcessingBarcode else { return }
        isProcessingBarcode = true
        
        print("Fetching product with barcode: \(barcode)")
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        guard let url = URL(string: baseURL + barcode) else {
            await setError("Invalid URL")
            isProcessingBarcode = false
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await setError("Invalid server response")
                isProcessingBarcode = false
                return
            }
            
            print("Server response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                do {
                    // Сначала декодируем как Dictionary для отладки
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("Received JSON: \(json)")
                    }
                    
                    struct ProductResponse: Codable {
                        let product: Product
                        let analysis: ProductAnalysis
                    }
                    
                    let response = try decoder.decode(ProductResponse.self, from: data)
                    print("Successfully decoded response")
                    
                    let product = Product(
                        barcode: response.product.barcode,
                        brand: response.product.brand,
                        category: response.product.category,
                        country: response.product.country,
                        creator: response.product.creator,
                        image: response.product.image,
                        image_ingredients: response.product.image_ingredients,
                        image_nutritions: response.product.image_nutritions,
                        ingredients: response.product.ingredients,
                        analysis: response.analysis
                    )
                    
                    await MainActor.run {
                        self.currentProduct = product
                        if !self.scannedProducts.contains(where: { $0.barcode == product.barcode }) {
                            self.scannedProducts.insert(product, at: 0)
                        }
                        self.isLoading = false
                        self.error = nil
                        self.showProductDetail = true
                    }
                } catch {
                    print("Decode error: \(error)")
                    print("Error details: \(error.localizedDescription)")
                    await setError("Failed to parse product data")
                }
            } else {
                await setError("Server error: \(httpResponse.statusCode)")
            }
        } catch URLError.timedOut {
            await setError("Connection timed out")
        } catch URLError.cannotConnectToHost {
            await setError("Cannot connect to server")
        } catch URLError.notConnectedToInternet {
            await setError("No internet connection")
        } catch {
            print("Network error: \(error)")
            await setError("Network error occurred")
        }
        
        isProcessingBarcode = false
    }
    
    private func setError(_ message: String) async {
        await MainActor.run {
            self.error = message
            self.isLoading = false
            self.showProductDetail = false
        }
    }
    
    func clearHistory() {
        scannedProducts.removeAll()
        try? FileManager.default.removeItem(at: productsFileURL)
    }
    
    func stopScanning() {
        isScanning = false
    }
    
    func startScanning() {
        isScanning = true
        showProductDetail = false
        error = nil
    }
} 
