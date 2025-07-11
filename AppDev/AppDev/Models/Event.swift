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
    let status: String?
    let cancellationReason: String?
    let cancellationDetails: String?
    let cancelledAt: Date?
    let cancelledBy: String?
    
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
        case id, title, date, endTime, startTime, location, imageUrl, attendees, category, price, maxCapacity, description, latitude, longitude, averageRating, totalReviews, status, cancellationReason, cancellationDetails, cancelledAt, cancelledBy
    }
    
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
        totalReviews: Int? = nil,
        status: String? = nil,
        cancellationReason: String? = nil,
        cancellationDetails: String? = nil,
        cancelledAt: Date? = nil,
        cancelledBy: String? = nil
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
        
        self.status = status
        self.cancellationReason = cancellationReason
        self.cancellationDetails = cancellationDetails
        self.cancelledAt = cancelledAt
        self.cancelledBy = cancelledBy

        self.recommendationScore = nil
        self.isRecommended = false
        self.distance = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
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
        
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        averageRating = try container.decodeIfPresent(Double.self, forKey: .averageRating)
        totalReviews = try container.decodeIfPresent(Int.self, forKey: .totalReviews)
        
        status = try container.decodeIfPresent(String.self, forKey: .status)
        cancellationReason = try container.decodeIfPresent(String.self, forKey: .cancellationReason)
        cancellationDetails = try container.decodeIfPresent(String.self, forKey: .cancellationDetails)
        cancelledAt = try container.decodeIfPresent(Date.self, forKey: .cancelledAt)
        cancelledBy = try container.decodeIfPresent(String.self, forKey: .cancelledBy)
        recommendationScore = nil
        isRecommended = false
        distance = nil
    }
    
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
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(cancellationReason, forKey: .cancellationReason)
        try container.encodeIfPresent(cancellationDetails, forKey: .cancellationDetails)
        try container.encodeIfPresent(cancelledAt, forKey: .cancelledAt)
        try container.encodeIfPresent(cancelledBy, forKey: .cancelledBy)
        
        // Note: We don't encode recommendationScore, isRecommended, or distance as they're runtime-only
    }
    
    var hasEnded: Bool {
        let isoFormatter = ISO8601DateFormatter()
        guard let endDateTime = isoFormatter.date(from: endTime) else { return false }
        return endDateTime < Date()
    }
    
    var isCancelled: Bool {
        return status == "cancelled"
    }
}

extension Event {
    var formattedDate: String {
        let isoFormatter = ISO8601DateFormatter()
        if let dateObj = isoFormatter.date(from: self.date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM yyyy"
            return formatter.string(from: dateObj)
        }
        return self.date
    }
    
    var formattedTime: String {
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