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
    @State private var selectedEvent: Event? = nil
    @State private var showingEventDetails = false
    private let geocoder = CLGeocoder()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HeaderView()
                    .padding(4)

                // Map
                ZStack {
                    Map(coordinateRegion: $region, annotationItems: events) { event in
                        MapAnnotation(coordinate: event.coordinate ?? region.center) {
                            VStack(spacing: 0) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.purple)
                                    .shadow(radius: 2)
                                    .onTapGesture {
                                        selectedEvent = event
                                        showingEventDetails = true
                                    }
                                
                                // Event title bubble
                                if selectedEvent?.id == event.id && showingEventDetails {
                                    Text(event.title)
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .shadow(radius: 2)
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .frame(height: 420)
                    .cornerRadius(0)
                    .padding(.bottom, 0)
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.black.opacity(0.1))
                            }
                        }
                    )
                }

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
            .sheet(isPresented: $showingEventDetails) {
                if let event = selectedEvent {
                    EventPreviewSheet(event: event)
                }
            }
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
            var tempEvents: [Event] = []
            for doc in documents {
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
                      let description = data["description"] as? String,
                      let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double
                else {
                    print("[EventsMapView] Skipping event with missing fields: \(doc.documentID)")
                    continue
                }
                let category = data["category"] as? String ?? "Other"
                let price = data["price"] as? Double ?? 0.0
                let distance: String? = "-"
                let event = Event(
                    id: id,
                    title: title,
                    date: date,
                    endTime: endTime,
                    startTime: startTime,
                    location: location,
                    imageUrl: imageUrl,
                    attendees: attendees,
                    category: category,
                    price: price,
                    maxCapacity: maxCapacity,
                    description: description,
                    latitude: latitude,
                    longitude: longitude,
                    distance: distance
                )
                tempEvents.append(event)
            }
            print("[EventsMapView] Final events count: \(tempEvents.count)")
            self.events = tempEvents
            if tempEvents.isEmpty {
                self.errorMessage = "No events found or missing coordinates for all events."
            }
            // Update map region to fit all events
            if let fitRegion = regionForEvents(tempEvents) {
                self.region = fitRegion
            }
        }
    }

    // Helper to fit all event pins
    func regionForEvents(_ events: [Event]) -> MKCoordinateRegion? {
        let coordinates = events.compactMap { $0.coordinate }
        guard !coordinates.isEmpty else { return nil }
        if coordinates.count == 1 {
            return MKCoordinateRegion(center: coordinates[0], span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
        }
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

struct EventPreviewSheet: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToEvent = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let imageUrl = URL(string: event.imageUrl) {
                        AsyncImage(url: imageUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 200)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(event.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "calendar")
                            Text("\(event.formattedDate), \(event.formattedTime)")
                        }
                        .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                            Text(event.location)
                        }
                        .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("\(event.attendees) going")
                        }
                        .foregroundColor(.purple)
                        
                        if event.price != nil {
                            HStack {
                                Image(systemName: "ticket.fill")
                                Text("€\(String(format: "%.2f", event.price ?? 0.0))")
                            }
                            .foregroundColor(.purple)
                        }
                    }
                    .padding()
                    
                    Button(action: {
                        navigateToEvent = true
                    }) {
                        Text("View Event Details")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Event Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToEvent) {
                EventView(eventId: event.id ?? "-1")
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
