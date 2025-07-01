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
    // New rating fields
    let averageRating: Double?
    let totalReviews: Int?

    
    var coordinate: CLLocationCoordinate2D? {
        if let lat = latitude, let lon = longitude {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return nil
    }
    var distance: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, title, date, endTime, startTime, location, imageUrl, attendees, category, price, maxCapacity, description, latitude, longitude, averageRating, totalReviews
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