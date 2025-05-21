//
//  Event.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

import Foundation
import MapKit

struct Event: Identifiable {
    let id: String // Firestore document ID
    let title: String
    let date: String
    let location: String
    let coordinate: CLLocationCoordinate2D?
    let imageUrl: String
    let attendees: Int
    let distance: String?
    let category: String
    let price: Double
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
        return self.date // fallback
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
}
