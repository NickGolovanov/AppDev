import FirebaseFirestore
import Foundation
import MapKit

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let date: String
    let endTime: String
    let startTime: String
    let location: String
    let imageUrl: String
    let attendees: Int
    let category: String
    let price: Double
    let maxCapacity: Int
    let description: String 
    let latitude: Double?
    let longitude: Double?
    let averageRating: Double?
    let totalReviews: Int?
    
    // Recommendation tracking - these are computed/runtime properties, not stored in Firestore
    var recommendationScore: Double? = nil
    var isRecommended: Bool = false

    
    var coordinate: CLLocationCoordinate2D? {
        if let lat = latitude, let lon = longitude {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return nil
    }
    var distance: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, title, date, endTime, startTime, location, imageUrl, attendees, category, price, maxCapacity, description, latitude, longitude, averageRating, totalReviews
        // Note: recommendationScore and isRecommended are NOT included as they're runtime-only properties
    }
    
    // Add memberwise initializer
    init(
        id: String? = nil,
        title: String,
        date: String,
        endTime: String,
        startTime: String,
        location: String,
        imageUrl: String,
        attendees: Int,
        category: String,
        price: Double,
        maxCapacity: Int,
        description: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        averageRating: Double? = nil,
        totalReviews: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.endTime = endTime
        self.startTime = startTime
        self.location = location
        self.imageUrl = imageUrl
        self.attendees = attendees
        self.category = category
        self.price = price
        self.maxCapacity = maxCapacity
        self.description = description
        self.latitude = latitude
        self.longitude = longitude
        self.averageRating = averageRating
        self.totalReviews = totalReviews
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode DocumentID
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(String.self, forKey: .date)
        endTime = try container.decode(String.self, forKey: .endTime)
        startTime = try container.decode(String.self, forKey: .startTime)
        location = try container.decode(String.self, forKey: .location)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        attendees = try container.decode(Int.self, forKey: .attendees)
        category = try container.decode(String.self, forKey: .category)
        price = try container.decode(Double.self, forKey: .price)
        maxCapacity = try container.decode(Int.self, forKey: .maxCapacity)
        description = try container.decode(String.self, forKey: .description)
        
        // Decode optional fields
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        averageRating = try container.decodeIfPresent(Double.self, forKey: .averageRating)
        totalReviews = try container.decodeIfPresent(Int.self, forKey: .totalReviews)
        
        // Initialize runtime properties with default values
        recommendationScore = nil
        isRecommended = false
        distance = nil
    }
    
    // Custom encoder that only encodes Firestore fields
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(_id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(location, forKey: .location)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encode(attendees, forKey: .attendees)
        try container.encode(category, forKey: .category)
        try container.encode(price, forKey: .price)
        try container.encode(maxCapacity, forKey: .maxCapacity)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        try container.encodeIfPresent(averageRating, forKey: .averageRating)
        try container.encodeIfPresent(totalReviews, forKey: .totalReviews)
        
        // Note: We don't encode recommendationScore, isRecommended, or distance as they're runtime-only
    }
    
    // Helper computed property to check if event has ended
    var hasEnded: Bool {
        let isoFormatter = ISO8601DateFormatter()
        guard let endDateTime = isoFormatter.date(from: endTime) else { return false }
        return endDateTime < Date()
    }
}

extension Event {
    var formattedDate: String {
        // Try to parse ISO8601 date string and format as '21 May 2025'
        let isoFormatter = ISO8601DateFormatter()
        if let dateObj = isoFormatter.date(from: self.date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM yyyy"
            return formatter.string(from: dateObj)
        }
        return self.date  // fallback
    }
    var formattedTime: String {
        // Try to parse ISO8601 date string and format as '10:00'
        let isoFormatter = ISO8601DateFormatter()
        if let dateObj = isoFormatter.date(from: self.date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: dateObj)
        }
        return ""
    }
    
    var formattedEndTime: String {
        let isoFormatter = ISO8601DateFormatter()
        if let dateObj = isoFormatter.date(from: self.endTime) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: dateObj)
        }
        return ""
    }
}