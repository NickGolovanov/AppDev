import MapKit
import SwiftUI

struct EventsView: View {
    @State private var selectedFilter = "All Events"
    let filters = ["All Events", "Music", "Art", "Food"]
    let featuredEvent = Event(
        title: "Summer Music Festival 2025",
        date: "July 15-17",
        location: "Central Park",
        coordinate: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041),
        imageUrl:
            "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80",
        attendees: 0,
        distance: "2.5km away"
    )
    let upcomingEvents = [
        Event(
            title: "Modern Art Exhibition",
            date: "May 20",
            location: "Art Gallery",
            coordinate: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041),
            imageUrl:
                "https://images.unsplash.com/photo-1515168833906-d2a3b82b3029?auto=format&fit=crop&w=800&q=80",
            attendees: 124,
            distance: "3.1km away"
        ),
        Event(
            title: "Food Truck Festival",
            date: "May 25",
            location: "Downtown",
            coordinate: CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041),
            imageUrl:
                "https://images.unsplash.com/photo-1464983953574-0892a716854b?auto=format&fit=crop&w=800&q=80",
            attendees: 89,
            distance: "3.1km away"
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Text("PartyPal")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.title2)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 16, height: 16)
                        .overlay(Text("3").font(.caption2).foregroundColor(.white))
                        .offset(x: 8, y: -8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

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
            VStack(alignment: .leading, spacing: 8) {
                Text("Featured Event")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: featuredEvent.imageUrl)) { image in
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
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), .clear]),
                        startPoint: .bottom, endPoint: .top
                    )
                    .cornerRadius(16)
                    .frame(height: 80)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(featuredEvent.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("\(featuredEvent.date) • \(featuredEvent.location)")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .padding(12)
                }
                .padding(.horizontal)
            }
            .padding(.top, 8)

            // Upcoming Events
            VStack(alignment: .leading, spacing: 8) {
                Text("Upcoming Events")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                ForEach(upcomingEvents) { event in
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: event.imageUrl)) { image in
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
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
            .padding(.top, 8)

            Spacer()

            // Floating Action Button
            HStack {
                Spacer()
                Button(action: {
                    // Add event action
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

            // Footer Navigation
//            FooterView()
        }
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview {
    EventsView()
}
