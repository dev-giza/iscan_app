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
    @Published var showPhotoUpload = false
    @Published var currentBarcode: String?
    
    private let baseURL = "https://iscan.store"
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
            self.currentBarcode = barcode
        }
        
        guard let url = URL(string: "\(baseURL)/find/\(barcode)") else {
            await setError("Invalid URL")
            isProcessingBarcode = false
            return
        }
        
        print("Fetching product with URL: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                print("Response Headers: \(httpResponse.allHeaderFields)")
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("Raw response data: \(responseString)")
            
            // Try to decode as ProductAnalysis first
            if let productAnalysis = try? decoder.decode(ProductAnalysis.self, from: data) {
                print("Successfully decoded as ProductAnalysis")
                // Convert ProductAnalysis to Product
                let product = Product(
                    id: UUID(),
                    product_name: productAnalysis.name,
                    barcode: productAnalysis.barcode,
                    manufacturer: productAnalysis.brand,
                    allergens: productAnalysis.allergens.joined(separator: ", "),
                    score: productAnalysis.rating_score,
                    nutrition: Nutrition(
                        proteins: productAnalysis.proteins,
                        fats: productAnalysis.fat,
                        carbohydrates: productAnalysis.carbohydrates,
                        calories: productAnalysis.energy_kcal,
                        kcal: productAnalysis.energy_kcal
                    ),
                    extra: Extra(
                        ingredients: "Ingredients not available",
                        explanation_score: productAnalysis.rating_description,
                        harmful_components: [],
                        recommendedfor: "Based on rating",
                        frequency: "Moderate",
                        alternatives: "Look for products with better ratings"
                    )
                )
                
                await MainActor.run {
                    self.currentProduct = product
                    if !self.scannedProducts.contains(where: { $0.barcode == product.barcode }) {
                        self.scannedProducts.insert(product, at: 0)
                    }
                    self.isLoading = false
                    self.error = nil
                    self.showProductDetail = true
                    self.showPhotoUpload = false
                }
            } else if let product = try? decoder.decode(Product.self, from: data) {
                print("Successfully decoded as Product")
                
                // Check if product data is empty
                if product.score == 0 && 
                   product.product_name == "Без названия" && 
                   product.manufacturer.isEmpty && 
                   product.allergens.isEmpty &&
                   product.nutrition.proteins == nil &&
                   product.nutrition.fats == nil &&
                   product.nutrition.carbohydrates == nil &&
                   product.nutrition.calories == nil &&
                   product.nutrition.kcal == nil &&
                   product.extra.ingredients.isEmpty &&
                   product.extra.recommendedfor.isEmpty &&
                   product.extra.frequency.isEmpty &&
                   product.extra.alternatives.isEmpty {
                    
                    await MainActor.run {
                        self.currentProduct = product
                        self.isLoading = false
                        self.showProductDetail = false
                        self.showPhotoUpload = true
                    }
                } else {
                    await MainActor.run {
                        self.currentProduct = product
                        if !self.scannedProducts.contains(where: { $0.barcode == product.barcode }) {
                            self.scannedProducts.insert(product, at: 0)
                        }
                        self.isLoading = false
                        self.error = nil
                        self.showProductDetail = true
                        self.showPhotoUpload = false
                    }
                }
            } else {
                print("Failed to decode response as either Product or ProductAnalysis")
                await MainActor.run {
                    self.isLoading = false
                    self.showProductDetail = false
                    self.showPhotoUpload = true
                }
            }
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            await MainActor.run {
                switch decodingError {
                case .dataCorrupted(let context):
                    self.error = "Invalid data format: \(context.debugDescription)"
                case .keyNotFound(let key, let context):
                    self.error = "Missing required field: \(key.stringValue) - \(context.debugDescription)"
                case .typeMismatch(let type, let context):
                    self.error = "Type mismatch: expected \(type) - \(context.debugDescription)"
                case .valueNotFound(let type, let context):
                    self.error = "Missing value: expected \(type) - \(context.debugDescription)"
                @unknown default:
                    self.error = "Unknown decoding error"
                }
                self.showPhotoUpload = true
            }
        } catch let urlError as URLError {
            print("URL error: \(urlError)")
            await MainActor.run {
                switch urlError.code {
                case .timedOut:
                    self.error = "Request timed out"
                case .notConnectedToInternet:
                    self.error = "No internet connection"
                case .networkConnectionLost:
                    self.error = "Network connection lost"
                default:
                    self.error = "Network error: \(urlError.localizedDescription)"
                }
            }
        } catch {
            print("Unknown error: \(error)")
            await MainActor.run {
                self.error = "Failed to fetch product: \(error.localizedDescription)"
            }
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
        showPhotoUpload = false
        error = nil
    }
} 
