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
                                            .frame(height: 200)
                                        .cornerRadius(16)
                                } placeholder: {
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(height: 200)
                                            .cornerRadius(16)
                                    }
                                } else {
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(height: 200)
                                        .cornerRadius(16)
                                }
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black.opacity(0.7), .clear]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                                .cornerRadius(16)
                                .frame(height: 200)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(firstEvent.title)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                    HStack {
                                        Text(firstEvent.formattedDate)
                                            .foregroundColor(.white.opacity(0.9))
                                            .font(.subheadline)
                                        Text(firstEvent.formattedTime)
                                            .foregroundColor(.white.opacity(0.9))
                                            .font(.subheadline)
                                        Text("•")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(firstEvent.location)
                                            .foregroundColor(.white.opacity(0.9))
                                            .font(.subheadline)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(16)
                            }
                            .padding(.horizontal)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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
                                HStack(spacing: 16) {
                                    if let imageUrl = URL(string: event.imageUrl) {
                                        AsyncImage(url: imageUrl) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                            .cornerRadius(12)
                                    } placeholder: {
                                            Rectangle()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(12)
                                        }
                                    } else {
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(12)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(event.title)
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                            .lineLimit(2)
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "calendar")
                                                .foregroundColor(.purple)
                                                .font(.caption)
                                            Text(event.formattedDate)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            Text(event.formattedTime)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(.purple)
                                                .font(.caption)
                                            Text(event.location)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                        
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
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.purple)
                                            .font(.system(size: 14, weight: .semibold))
                                            .padding(8)
                                            .background(Color.purple.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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
                    // Instead of returning nil, return a default Event with fallback values
                    let coordinate: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)
                    let distance: String? = "-"
                    return Event(id: id, title: "Untitled", date: "", location: "", coordinate: coordinate, imageUrl: "", attendees: 0, distance: distance, category: "Other", price: 0.0)
                }
                // Dummy values for coordinate and distance
                let coordinate: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)
                let distance: String? = "-"
                let category = data["category"] as? String ?? "Other"
                let price = data["price"] as? Double ?? 0.0
                return Event(id: id, title: title, date: date, location: location, coordinate: coordinate, imageUrl: imageUrl, attendees: attendees, distance: distance, category: category, price: price)
            }
        }
    }
}

#Preview {
    EventsView()
}
