import SwiftUI

struct Event: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let location: String
    let image: String
    let attendees: Int
}

struct EventPage: View {
    @State private var selectedFilter = "All Events"
    let filters = ["All Events", "Music", "Art", "Food"]
    let featuredEvent = Event(title: "Summer Music Festival 2025", date: "July 15-17", location: "Central Park", image: "featured", attendees: 0)
    let upcomingEvents = [
        Event(title: "Modern Art Exhibition", date: "May 20", location: "Art Gallery", image: "art", attendees: 124),
        Event(title: "Food Truck Festival", date: "May 25", location: "Downtown", image: "food", attendees: 89)
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
                Image("profile") // Replace with your profile image
                    .resizable()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            }
            .padding()
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search events...", text: .constant(""))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(filters, id: \.self) { filter in
                        Text(filter)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? Color.purple.opacity(0.2) : Color(.systemGray5))
                            .foregroundColor(selectedFilter == filter ? .purple : .black)
                            .cornerRadius(20)
                            .onTapGesture { selectedFilter = filter }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 8)
            
            // Featured Event
            VStack(alignment: .leading) {
                Text("Featured Event")
                    .font(.headline)
                    .padding(.horizontal)
                ZStack(alignment: .bottomLeading) {
                    Image(featuredEvent.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .cornerRadius(16)
                    VStack(alignment: .leading) {
                        Text(featuredEvent.title)
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                        Text("\(featuredEvent.date) • \(featuredEvent.location)")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.7), .clear]), startPoint: .bottom, endPoint: .top))
                }
                .padding(.horizontal)
            }
            .padding(.top)
            
            // Upcoming Events
            VStack(alignment: .leading) {
                Text("Upcoming Events")
                    .font(.headline)
                    .padding(.horizontal)
                ForEach(upcomingEvents) { event in
                    HStack {
                        Image(event.image)
                            .resizable()
                            .frame(width: 60, height: 60)
                            .cornerRadius(12)
                        VStack(alignment: .leading) {
                            Text(event.title)
                                .font(.headline)
                            Text("\(event.date) • \(event.location)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.purple)
                                Text("\(event.attendees) going")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
            .padding(.top)
            
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
                        .padding()
                        .background(Color.purple)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
            
            // Bottom Navigation Bar
            HStack {
                Spacer()
                VStack {
                    Image(systemName: "house")
                    Text("Home").font(.caption)
                }
                Spacer()
                VStack {
                    Image(systemName: "ticket")
                    Text("Tickets").font(.caption)
                }
                Spacer()
                VStack {
                    Image(systemName: "calendar")
                    Text("Events").font(.caption)
                }
                Spacer()
                VStack {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Chat").font(.caption)
                }
                Spacer()
                VStack {
                    Image(systemName: "person.crop.circle")
                    Text("Profile").font(.caption)
                }
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
        }
        .background(Color.white.ignoresSafeArea())
    }
}

struct EventPage_Previews: PreviewProvider {
    static var previews: some View {
        EventPage()
    }
} 