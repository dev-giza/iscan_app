import Foundation

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
    
    init(id: UUID = UUID(),
         barcode: String,
         brand: String,
         category: String,
         country: String,
         creator: String,
         image: String,
         image_ingredients: String,
         image_nutritions: String,
         ingredients: String) {
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
    }
    
    enum CodingKeys: String, CodingKey {
        case id, barcode, brand, category, country, creator, image
        case image_ingredients, image_nutritions, ingredients
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode) ?? "Unknown"
        brand = try container.decodeIfPresent(String.self, forKey: .brand) ?? "Unknown"
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "Unknown"
        country = try container.decodeIfPresent(String.self, forKey: .country) ?? "Unknown"
        creator = try container.decodeIfPresent(String.self, forKey: .creator) ?? "Unknown"
        image = try container.decodeIfPresent(String.self, forKey: .image) ?? "Unknown"
        image_ingredients = try container.decodeIfPresent(String.self, forKey: .image_ingredients) ?? "Unknown"
        image_nutritions = try container.decodeIfPresent(String.self, forKey: .image_nutritions) ?? "Unknown"
        ingredients = try container.decodeIfPresent(String.self, forKey: .ingredients) ?? "Unknown"
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
    }
} 