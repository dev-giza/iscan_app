import Foundation
import SwiftUI

struct Product: Codable, Identifiable, Equatable {
    let id: UUID
    let product_name: String
    let barcode: String
    let manufacturer: String
    let allergens: String
    let score: Int
    let nutrition: Nutrition
    let extra: Extra
    let image_front: String?
    let image_ingredients: String?
    
    init(id: UUID = UUID(),
         product_name: String,
         barcode: String,
         manufacturer: String,
         allergens: String,
         score: Int,
         nutrition: Nutrition,
         extra: Extra,
         image_front: String? = nil,
         image_ingredients: String? = nil) {
        self.id = id
        self.product_name = product_name
        self.barcode = barcode
        self.manufacturer = manufacturer
        self.allergens = allergens
        self.score = score
        self.nutrition = nutrition
        self.extra = extra
        self.image_front = image_front
        self.image_ingredients = image_ingredients
    }
    
    enum CodingKeys: String, CodingKey {
        case id, product_name, barcode, manufacturer, allergens, score, nutrition, extra, image_front, image_ingredients
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        product_name = try container.decode(String.self, forKey: .product_name)
        barcode = try container.decode(String.self, forKey: .barcode)
        manufacturer = try container.decode(String.self, forKey: .manufacturer)
        allergens = try container.decode(String.self, forKey: .allergens)
        score = try container.decode(Int.self, forKey: .score)
        nutrition = try container.decode(Nutrition.self, forKey: .nutrition)
        extra = try container.decode(Extra.self, forKey: .extra)
        image_front = try container.decodeIfPresent(String.self, forKey: .image_front)
        image_ingredients = try container.decodeIfPresent(String.self, forKey: .image_ingredients)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(product_name, forKey: .product_name)
        try container.encode(barcode, forKey: .barcode)
        try container.encode(manufacturer, forKey: .manufacturer)
        try container.encode(allergens, forKey: .allergens)
        try container.encode(score, forKey: .score)
        try container.encode(nutrition, forKey: .nutrition)
        try container.encode(extra, forKey: .extra)
        try container.encode(image_front, forKey: .image_front)
        try container.encode(image_ingredients, forKey: .image_ingredients)
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.barcode == rhs.barcode
    }
}

struct Nutrition: Codable {
    let proteins: Double?
    let fats: Double?
    let carbohydrates: Double?
    let calories: Double?
    let kcal: Double?
}

struct Extra: Codable {
    let ingredients: String
    let explanation_score: String
    let harmful_components: [HarmfulComponent]
    let recommendedfor: String
    let frequency: String
    let alternatives: String
}

struct HarmfulComponent: Codable {
    let name: String
    let effect: String
    let recommendation: String
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