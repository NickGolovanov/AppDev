import SwiftUI
import MapKit

struct Event: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let coordinate: CLLocationCoordinate2D
    let distance: String
    let date: String
    let imageName: String // Use systemName or asset name
}

struct EventsMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.3702, longitude: 4.8952), // Amsterdam
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    
    let events = [
        Event(
            name: "Summer Night Party",
            location: "Club Matrix, 2.3km away",
            coordinate: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041),
            distance: "2.3km away",
            date: "Tonight, 10:00 PM",
            imageName: "party1"
        ),
        Event(
            name: "Live Jazz Night",
            location: "Blue Note, 3.1km away",
            coordinate: CLLocationCoordinate2D(latitude: 52.3667, longitude: 4.8945),
            distance: "3.1km away",
            date: "Tomorrow, 8:30 PM",
            imageName: "party2"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("PartyPal")
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(Color.purple)
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 18, height: 18)
                        .overlay(Text("3").font(.caption2).foregroundColor(.white))
                        .offset(x: 10, y: -10)
                }
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 4)
            .background(Color.white)
            .shadow(color: Color(.systemGray5), radius: 1, y: 1)
            
            // Map (fixed height)
            Map(coordinateRegion: $region, annotationItems: events) { event in
                MapMarker(coordinate: event.coordinate, tint: .red)
            }
            .frame(height: 340)
            .cornerRadius(0)
            .padding(.bottom, 0)
            
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

struct EventCard: View {
    let event: Event
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Event image (placeholder)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 54, height: 54)
                .overlay(
                    Image(event.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipped()
                )
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                    .fontWeight(.semibold)
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

struct EventsMapView_Previews: PreviewProvider {
    static var previews: some View {
        EventsMapView()
    }
} 