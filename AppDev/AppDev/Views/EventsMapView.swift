import MapKit
import SwiftUI

struct EventsMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.3702, longitude: 4.8952),  // Amsterdam
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    let events = [
        Event(
            title: "Summer Night Party",
            date: "Tonight, 10:00 PM",
            location: "Club Matrix, 2.3km away",
            coordinate: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041),
            imageUrl: "party1",
            attendees: 124,
            distance: "2.3km away"
        ),
        Event(
            title: "Live Jazz Night",
            date: "Tomorrow, 8:30 PM",
            location: "Blue Note, 3.1km away",
            coordinate: CLLocationCoordinate2D(latitude: 52.3667, longitude: 4.8945),
            imageUrl: "party2",
            attendees: 124,
            distance: "3.1km away"
        ),
    ]

    @available(iOS, deprecated: 17.0, message: "Will migrate soon")
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HeaderView()
                    .padding(4)

                // Map (increased height)
                Map(coordinateRegion: $region, annotationItems: events) { event in
                    MapMarker(coordinate: event.coordinate, tint: .red)
                }
                .frame(height: 420)
                .cornerRadius(0)
                .padding(.bottom, 0)

                // Spacing between map and cards
                Spacer().frame(height: 16)

                // Event Cards (below the map, not overlapping)
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color(.systemGray4))
                        .frame(width: 60, height: 6)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(events) { event in
                                EventCard(event: event)
                            }
                        }
                        .padding(.bottom, 16)
                        .padding(.top, 4)
                    }
                    .frame(maxHeight: 180)
                }
                .background(Color.white)
                .cornerRadius(28)
                .shadow(color: Color(.systemGray3), radius: 16, x: 0, y: 8)
                .padding(.horizontal, 16)
                .padding(.top, 0)
                .padding(.bottom, 16)
                Spacer()
            }
            .background(Color(.systemGray6).ignoresSafeArea())
        }
    }
}

struct EventCard: View {
    let event: Event
    var body: some View {
        NavigationLink(destination: EventView()) {
            HStack(alignment: .top, spacing: 12) {
                // Event image (placeholder)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 54, height: 54)
                    .overlay(
                        Image(event.imageUrl)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 54, height: 54)
                            .clipped()
                    )
                    .cornerRadius(8)
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text(event.location)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text(event.date)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: "arrow.right")
                        .foregroundColor(Color.purple)
                }
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: Color(.systemGray4).opacity(0.18), radius: 6, x: 0, y: 3)
            .padding(.horizontal, 2)
        }
    }
}

struct EventsMapView_Previews: PreviewProvider {
    static var previews: some View {
        EventsMapView()
    }
}
