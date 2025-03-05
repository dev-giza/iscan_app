import Foundation
import SwiftUI

struct Product: Codable, Identifiable {
    let id: UUID
    let barcode: String
    let brand: String
    let category: String
    let country: String
    let creator: String
    let image: String
    let image_ingredients: String
    let image_nutritions: String
    let ingredients: String
    let analysis: ProductAnalysis?
    
    init(id: UUID = UUID(),
         barcode: String,
         brand: String,
         category: String,
         country: String,
         creator: String,
         image: String,
         image_ingredients: String,
         image_nutritions: String,
         ingredients: String,
         analysis: ProductAnalysis? = nil) {
        self.id = id
        self.barcode = barcode
        self.brand = brand
        self.category = category
        self.country = country
        self.creator = creator
        self.image = image
        self.image_ingredients = image_ingredients
        self.image_nutritions = image_nutritions
        self.ingredients = ingredients
        self.analysis = analysis
    }
    
    enum CodingKeys: String, CodingKey {
        case id, barcode, brand, category, country, creator, image
        case image_ingredients, image_nutritions, ingredients, analysis
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        barcode = try container.decode(String.self, forKey: .barcode)
        brand = try container.decode(String.self, forKey: .brand)
        category = try container.decode(String.self, forKey: .category)
        country = try container.decode(String.self, forKey: .country)
        creator = try container.decode(String.self, forKey: .creator)
        image = try container.decode(String.self, forKey: .image)
        image_ingredients = try container.decode(String.self, forKey: .image_ingredients)
        image_nutritions = try container.decode(String.self, forKey: .image_nutritions)
        ingredients = try container.decode(String.self, forKey: .ingredients)
        analysis = try container.decodeIfPresent(ProductAnalysis.self, forKey: .analysis)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(barcode, forKey: .barcode)
        try container.encode(brand, forKey: .brand)
        try container.encode(category, forKey: .category)
        try container.encode(country, forKey: .country)
        try container.encode(creator, forKey: .creator)
        try container.encode(image, forKey: .image)
        try container.encode(image_ingredients, forKey: .image_ingredients)
        try container.encode(image_nutritions, forKey: .image_nutritions)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encode(analysis, forKey: .analysis)
    }
}

struct ProductAnalysis: Codable {
    let barcode: String
    let name: String
    let brand: String
    let nutri_score: String
    let nutri_score_points: Int
    let nova_group: Int
    let energy_kcal: Double
    let proteins: Double
    let carbohydrates: Double
    let sugars: Double
    let fat: Double
    let saturated_fat: Double
    let salt: Double
    let allergens: [String]
    let additives: [String]
    let eco_score: String
    let eco_score_points: Int
    let labels: [String]
    let rating_score: Int
    let rating_description: String
    let rating_details: RatingDetails
    let health_rating: String
    let environmental_rating: String
    
    var ratingColor: Color {
        switch rating_score {
        case 0...20: return .red
        case 21...40: return .orange
        case 41...60: return .yellow
        case 61...80: return .green
        default: return .green
        }
    }
}

struct RatingDetails: Codable {
    let nutri_score_points: Int
    let additives_bonus: Int
    let nova_bonus: Int
    let eco_penalty: Int
} 