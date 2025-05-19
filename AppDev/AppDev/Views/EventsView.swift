import MapKit
import SwiftUI
import FirebaseFirestore

struct EventsView: View {
    @State private var selectedFilter = "All Events"
    @State private var showCreateEvent = false
    let filters = ["All Events", "Music", "Art", "Food"]
    @State private var events: [Event] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    HeaderView()
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search events...", text: .constant(""))
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 4)

                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filters, id: \.self) { filter in
                                Text(filter)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedFilter == filter
                                            ? Color.purple.opacity(0.2) : Color(.systemGray5)
                                    )
                                    .foregroundColor(selectedFilter == filter ? .purple : .black)
                                    .font(.subheadline)
                                    .fontWeight(selectedFilter == filter ? .semibold : .regular)
                                    .cornerRadius(20)
                                    .onTapGesture { selectedFilter = filter }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)

                    // Featured Event
                    if let firstEvent = events.first {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Featured Event")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            ZStack(alignment: .bottomLeading) {
                                if let imageUrl = URL(string: firstEvent.imageUrl) {
                                    AsyncImage(url: imageUrl) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 160)
                                            .cornerRadius(16)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(height: 160)
                                            .cornerRadius(16)
                                    }
                                } else {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(height: 160)
                                        .cornerRadius(16)
                                }
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black.opacity(0.7), .clear]),
                                    startPoint: .bottom, endPoint: .top
                                )
                                .cornerRadius(16)
                                .frame(height: 80)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(firstEvent.title)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("\(firstEvent.date) • \(firstEvent.location)")
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                }
                                .padding(12)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 8)
                    }

                    // Upcoming Events
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Upcoming Events")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        if isLoading {
                            ProgressView().padding()
                        } else if let errorMessage = errorMessage {
                            Text(errorMessage).foregroundColor(.red).padding()
                        } else {
                            ForEach(events) { event in
                                HStack(spacing: 12) {
                                    if let imageUrl = URL(string: event.imageUrl) {
                                        AsyncImage(url: imageUrl) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 56, height: 56)
                                                .cornerRadius(12)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(Color(.systemGray5))
                                                .frame(width: 56, height: 56)
                                                .cornerRadius(12)
                                        }
                                    } else {
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(width: 56, height: 56)
                                            .cornerRadius(12)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.title)
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                        Text("\(event.date) • \(event.location)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        HStack(spacing: 4) {
                                            Image(systemName: "person.2.fill")
                                                .foregroundColor(.purple)
                                                .font(.caption)
                                            Text("\(event.attendees) going")
                                                .font(.caption)
                                                .foregroundColor(.purple)
                                        }
                                    }
                                    Spacer()
                                    NavigationLink(destination: EventView(eventId: event.id)) {
                                        Image(systemName: "arrow.right")
                                            .foregroundColor(Color.purple)
                                    }
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 8)

                    Spacer()

                    // Floating Action Button
                    HStack {
                        Spacer()
                        Button(action: {
                            showCreateEvent = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding(24)
                                .background(Color.purple)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 8)
                    }
                    .padding(.top, 16)
                }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationDestination(isPresented: $showCreateEvent) {
                CreateEventView()
            }
        }
        .onAppear(perform: fetchEvents)
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
                // Map Firestore data to Event model
                guard let title = data["title"] as? String,
                      let date = data["date"] as? String,
                      let location = data["location"] as? String,
                      let imageUrl = data["imageUrl"] as? String,
                      let attendees = data["attendees"] as? Int else {
                    return nil
                }
                // Dummy values for coordinate and distance
                let coordinate: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)
                let distance: String? = "-"
                return Event(id: id, title: title, date: date, location: location, coordinate: coordinate, imageUrl: imageUrl, attendees: attendees, distance: distance)
            }
        }
    }
}

#Preview {
    EventsView()
}
