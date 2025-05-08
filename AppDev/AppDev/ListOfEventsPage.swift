import SwiftUI

struct EventListItem: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let time: String
    let location: String
    let imageUrl: String
    let organizer: String
    let price: String
    let ticketsLeft: Int
}

struct ListOfEventsPage: View {
    @State private var events = [
        EventListItem(
            title: "Tech Innovation Summit 2025",
            date: "May 15, 2025",
            time: "9:00 AM",
            location: "Convention Center, Silicon Valley",
            imageUrl: "https://images.unsplash.com/photo-1464983953574-0892a716854b?auto=format&fit=crop&w=800&q=80",
            organizer: "TechEvents Inc.",
            price: "$299",
            ticketsLeft: 46
        ),
        EventListItem(
            title: "Summer Music Festival",
            date: "July 15, 2025",
            time: "5:00 PM",
            location: "Central Park, Amsterdam",
            imageUrl: "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80",
            organizer: "MusicLive NL",
            price: "$49",
            ticketsLeft: 120
        ),
        EventListItem(
            title: "Art & Food Expo",
            date: "June 10, 2025",
            time: "12:00 PM",
            location: "Art Gallery, Rotterdam",
            imageUrl: "https://images.unsplash.com/photo-1515168833906-d2a3b82b3029?auto=format&fit=crop&w=800&q=80",
            organizer: "ArtFood Events",
            price: "Free",
            ticketsLeft: 0
        )
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
            
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(events) { event in
                        EventCardView(event: event)
                    }
                }
                .padding(.vertical)
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

struct EventCardView: View {
    let event: EventListItem
    @State private var isFavorite = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: event.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 180)
                }
                Button(action: { isFavorite.toggle() }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .white)
                        .padding(10)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                        .padding(10)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.black)
                HStack(spacing: 12) {
                    Label(event.date, systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Label(event.time, systemImage: "clock")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.purple)
                    Text(event.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color(.systemGray4), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .onTapGesture {
            // Action for tapping the card (e.g., navigate to details)
        }
    }
}

struct ListOfEventsPage_Previews: PreviewProvider {
    static var previews: some View {
        ListOfEventsPage()
    }
} 