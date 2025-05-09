import SwiftUI
import MapKit

struct PartyPalView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            Text("Tickets")
                .tabItem {
                    Image(systemName: "ticket.fill")
                    Text("Tickets")
                }
            Text("Events")
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
            Text("Chat")
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Chat")
                }
            Text("Profile")
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
    }
}

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Header
                HStack {
                    Text("PartyPal")
                        .font(.title2).bold().foregroundColor(.purple)
                    Spacer()
                    Image(systemName: "bell.fill")
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                }
                .padding(.horizontal)

                // Trending Tonight
                Text("🔥 Trending Tonight")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        trendingCard(title: "Neon Dreams", subtitle: "22:00 · Club Matrix", tags: ["House", "Hot"], imageName: "party1", bgColor: .purple)
                        trendingCard(title: "Beach Blast", subtitle: "20:00 · Zandvoort", tags: ["Beach", "Chill"], imageName: "party2", bgColor: .pink)
                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 20)
                }
                .frame(height: 130)

                // Upcoming Events
                Text("🗓️ Upcoming Events")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 15) {
                    eventCard(name: "Amsterdam Student Night", date: "May 5, 2025 · 21:00", dressCode: "Smart Casual", price: "€5")
                    eventCard(name: "TU Delft Spring Party", date: "May 7, 2025 · 22:00", dressCode: "Casual", price: "€10")
                }
                .padding(.horizontal)

                // Map
                Image("map")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                // Host Party Section
                hostPartyCard()
                    .padding(.horizontal)
                    .padding(.bottom, 80)
            }
            .padding(.top)
        }
    }

    func trendingCard(title: String, subtitle: String, tags: [String], imageName: String, bgColor: Color) -> some View {
        let cardWidth = UIScreen.main.bounds.width * 0.7
        return VStack(alignment: .leading, spacing: 0) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: cardWidth, height: 80)
                .clipped()
                .cornerRadius(10, corners: [.topLeft, .topRight])

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                }
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(8)
            .frame(width: cardWidth, alignment: .leading)
        }
        .frame(width: cardWidth)
        .background(bgColor)
        .cornerRadius(12)
    }

    func eventCard(name: String, date: String, dressCode: String, price: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name).font(.headline)
                Text(date).font(.caption).foregroundColor(.gray)
                HStack {
                    Text(dressCode).font(.caption2).padding(4).background(Color.purple.opacity(0.2)).cornerRadius(4)
                    Text(price).font(.caption2).padding(4).background(Color.green.opacity(0.2))
                    .cornerRadius(4)
                }
            }
            Spacer()
            Button("Join") {
                // Join action
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

    func hostPartyCard() -> some View {
    HStack {
        VStack(alignment: .leading, spacing: 6) {
            Text("✨ Host your own party?")
                .font(.headline)
                .foregroundColor(.white)
            Text("Create and manage your event with ease")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
        Spacer()
        Button("Create Party") {
            // Action
        }
        .font(.headline)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
        .foregroundColor(.purple)
        .cornerRadius(10)
    }
    .padding()
    .background(
        LinearGradient(colors: [Color.purple, Color.pink], startPoint: .leading, endPoint: .trailing)
    )
    .cornerRadius(15)
}

struct PartyPalView_Previews: PreviewProvider {
    static var previews: some View {
        PartyPalView()
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}