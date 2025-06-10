import MapKit
import SwiftUI
import FirebaseFirestore

struct EventsMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.3702, longitude: 4.8952),  // Amsterdam
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @State private var events: [Event] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HeaderView()
                    .padding(4)

                // Map
                Map(coordinateRegion: $region, annotationItems: events) { event in
                    MapMarker(coordinate: event.coordinate ?? region.center, tint: .purple)
                }
                .frame(height: 420)
                .cornerRadius(0)
                .padding(.bottom, 0)

                // Spacing between map and cards
                Spacer().frame(height: 16)

                // Event Cards
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
        .onAppear {
            fetchEvents()
        }
    }

    func fetchEvents() {
        isLoading = true
        errorMessage = nil
        let db = Firestore.firestore()
        db.collection("events").order(by: "createdAt", descending: true).getDocuments { snapshot, error in
            isLoading = false
            if let error = error {
                errorMessage = "Failed to load events: \(error.localizedDescription)"
                return
            }
            guard let documents = snapshot?.documents else {
                errorMessage = "No events found."
                return
            }
            events = documents.compactMap { doc in
                let data = doc.data()
                let id = doc.documentID
                guard let title = data["title"] as? String,
                      let date = data["date"] as? String,
                      let endTime = data["endTime"] as? String,
                      let startTime = data["startTime"] as? String,
                      let location = data["location"] as? String,
                      let imageUrl = data["imageUrl"] as? String,
                      let attendees = data["attendees"] as? Int,
                      let maxCapacity = data["maxCapacity"] as? Int,
                      let description = data["description"] as? String
                else {
                    return nil
                }
                let coordinate: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)
                let distance: String? = "-"
                let category = data["category"] as? String ?? "Other"
                let price = data["price"] as? Double ?? 0.0
                return Event(id: id, title: title, date: date, endTime: endTime, startTime: startTime, location: location, imageUrl: imageUrl, attendees: attendees, category: category, price: price, maxCapacity: maxCapacity, description: description, coordinate: coordinate, distance: distance)
            }
        }
    }
}

struct EventCard: View {
    let event: Event
    var body: some View {
        NavigationLink(destination: EventView(eventId: event.id ?? "-1")) {
            HStack(alignment: .top, spacing: 12) {
                if let imageUrl = URL(string: event.imageUrl) {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 54, height: 54)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 54, height: 54)
                    }
                    .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 54, height: 54)
                        .cornerRadius(8)
                }
                
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text("\(event.formattedDate), \(event.formattedTime)")
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

#Preview {
    EventsMapView()
}
