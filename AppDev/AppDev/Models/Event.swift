//
//  Event.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

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

    
    var coordinate: CLLocationCoordinate2D? {
        if let lat = latitude, let lon = longitude {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return nil
    }
    var distance: String? = nil

    enum CodingKeys: String, CodingKey {
            case id, title, date, endTime, startTime, location, imageUrl, attendees, category, price, maxCapacity, description, latitude, longitude
    }
}
//
//extension Event: Decodable {
//    enum CodingKeys: String, CodingKey {
//        case id, title, date, endTime, startTime, location, imageUrl, attendees, category, price, maxCapacity, description
//    }
//    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.id = try container.decode(String.self, forKey: .id)
//        self.title = try container.decode(String.self, forKey: .title)
//        self.date = try container.decode(String.self, forKey: .date)
//        self.endTime = try container.decode(String.self, forKey: .endTime)
//        self.startTime = try container.decode(String.self, forKey: .startTime)
//        self.location = try container.decode(String.self, forKey: .location)
//        self.imageUrl = try container.decode(String.self, forKey: .imageUrl)
//        self.attendees = try container.decode(Int.self, forKey: .attendees)
//        self.category = try container.decode(String.self, forKey: .category)
//        self.price = try container.decode(Double.self, forKey: .price)
//        self.maxCapacity = try container.decode(Int.self, forKey: .maxCapacity)
//        self.description = try container.decodeIfPresent(String.self, forKey: .description)
//        self.coordinate = nil
//        self.distance = nil
//    }
//}

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
