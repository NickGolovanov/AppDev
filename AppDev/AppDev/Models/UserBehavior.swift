import FirebaseFirestore
import Foundation

struct UserBehavior: Codable {
    @DocumentID var id: String?
    let userId: String
    let eventId: String
    let actionType: ActionType
    let timestamp: Date
    let eventCategory: String?
    let eventPrice: Double?
    let eventLocation: String?
    
    enum ActionType: String, Codable, CaseIterable {
        case attended = "attended"
        case saved = "saved"
        case clicked = "clicked"
        case shared = "shared"
        case rated = "rated"
        case purchased = "purchased"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, userId, eventId, actionType, timestamp, eventCategory, eventPrice, eventLocation
    }
}

struct UserPreferences: Codable {
    @DocumentID var id: String?
    let userId: String
    var preferredCategories: [String: Double]
    var preferredPriceRange: ClosedRange<Double>?
    var preferredLocations: [String: Double]
    var preferredTimes: [String: Double]
    var lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId, preferredCategories, preferredLocations, preferredTimes, lastUpdated
        case minPrice, maxPrice
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        preferredCategories = try container.decode([String: Double].self, forKey: .preferredCategories)
        preferredLocations = try container.decode([String: Double].self, forKey: .preferredLocations)
        preferredTimes = try container.decode([String: Double].self, forKey: .preferredTimes)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
    
        if let minPrice = try container.decodeIfPresent(Double.self, forKey: .minPrice),
           let maxPrice = try container.decodeIfPresent(Double.self, forKey: .maxPrice) {
            preferredPriceRange = minPrice...maxPrice
        } else {
            preferredPriceRange = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(preferredCategories, forKey: .preferredCategories)
        try container.encode(preferredLocations, forKey: .preferredLocations)
        try container.encode(preferredTimes, forKey: .preferredTimes)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        
        if let priceRange = preferredPriceRange {
            try container.encode(priceRange.lowerBound, forKey: .minPrice)
            try container.encode(priceRange.upperBound, forKey: .maxPrice)
        }
    }
    
    init(userId: String) {
        self.userId = userId
        self.preferredCategories = [:]
        self.preferredLocations = [:]
        self.preferredTimes = [:]
        self.preferredPriceRange = nil
        self.lastUpdated = Date()
    }
}