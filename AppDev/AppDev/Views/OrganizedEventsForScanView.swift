//
//  OrganizedEventsForScanView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/14/24.
//

import SwiftUI
import FirebaseFirestore

struct OrganizedEventsForScanView: View {
    var organizedEvents: [Event]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select an Event to Scan QR Code")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            if organizedEvents.isEmpty {
                Spacer()
                Text("You haven't organized any events yet.")
                    .foregroundColor(.gray)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(organizedEvents) { event in
                            eventScanCard(event: event)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Scan QR Code")
        .navigationBarTitleDisplayMode(.inline)
    }

    func eventScanCard(event: Event) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#E9DDFD"))
                    .frame(width: 40, height: 40)

                if let imageUrl = URL(string: event.imageUrl), !event.imageUrl.isEmpty {
                    AsyncImage(url: imageUrl) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                    } placeholder: {
                        Image(systemName: "calendar")
                            .foregroundColor(Color(hex: "#7131C5"))
                    }
                } else {
                    Image(systemName: "calendar")
                        .foregroundColor(Color(hex: "#7131C5"))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("\(event.formattedDate), \(event.formattedTime)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            NavigationLink(destination: QRCodeScannerView(eventName: event.title, eventId: event.id ?? "")) {
                Text("Scan")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color(hex: "#7131C5")) // Using the purple color from your app
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// Removed duplicate Event struct and Color+Extensions as they are defined elsewhere in the project

#Preview {
    OrganizedEventsForScanView(organizedEvents: [
        Event(id: "1", title: "My Awesome Party", date: "2025-06-15", endTime: "10:00 PM", startTime: "7:00 PM", location: "Central Park", imageUrl: "https://example.com/image1.jpg", attendees: 50, category: "Music", price: 25.0, maxCapacity: 100, description: "A super fun party!"),
        Event(id: "2", title: "Tech Meetup", date: "2025-07-01", endTime: "9:00 PM", startTime: "6:00 PM", location: "Tech Hub", imageUrl: "", attendees: 20, category: "Tech", price: 0.0, maxCapacity: 50, description: "Networking for developers.")
    ])
} 