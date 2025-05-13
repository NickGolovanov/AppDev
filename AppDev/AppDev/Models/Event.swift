//
//  Event.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

import Foundation
import MapKit

struct Event: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let location: String
    let coordinate: CLLocationCoordinate2D
    let imageUrl: String
    let attendees: Int
    let distance: String
}
