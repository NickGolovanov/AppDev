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
    let organizerId: String
    
    var coordinate: CLLocationCoordinate2D? {
        if let lat = latitude, let lon = longitude {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return nil
    }
    var distance: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, title, date, endTime, startTime, location, imageUrl, attendees, category, price, maxCapacity, description, latitude, longitude, organizerId // ADD organizerId HERE
    }

    var averageRating: Double?
    var totalRatings: Int?
    var canRate: Bool?
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
    
    var hasEventPassed: Bool {
        let isoFormatter = ISO8601DateFormatter()
        if let eventDate = isoFormatter.date(from: self.endTime) {
            return eventDate < Date()
        }
        return false
    }
    
    var eventStatus: String {
        if hasEventPassed {
            return "Past Event"
        } else {
            let isoFormatter = ISO8601DateFormatter()
            if let eventDate = isoFormatter.date(from: self.date) {
                let now = Date()
                if eventDate <= now {
                    return "Happening Now"
                } else {
                    return "Upcoming"
                }
            }
        }
        return "Unknown"
    }
}
