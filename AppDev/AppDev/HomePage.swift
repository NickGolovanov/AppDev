import SwiftUI

// ...existing code...
struct HomePage: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("PartyPal")
                    .font(.title2).bold().foregroundColor(.purple)
                Spacer()
                HStack(spacing: 16) {
                    Image(systemName: "bell")
                    Image(systemName: "person.crop.circle")
                }
                .font(.title2)
            }
            .padding()
            .background(Color.white)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Trending Tonight
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔥 Trending Tonight")
                            .font(.headline)
                        // Trending Event Card
                        ZStack(alignment: .bottomLeading) {
                            Image(uiImage: UIImage(named: "Screenshot 2025-05-08 132241") ?? UIImage())
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                                .cornerRadius(16)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("House")
                                        .font(.caption2)
                                        .padding(4)
                                        .background(Color.purple.opacity(0.2))
                                        .cornerRadius(4)
                                    Text("Hot")
                                        .font(.caption2)
                                        .padding(4)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(4)
                                }
                                Text("Neon Dreams")
                                    .font(.headline).bold()
                                Text("22:00 • Club Matrix")
                                    .font(.caption)
                            }
                            .padding()
                            .background(
                                LinearGradient(gradient: Gradient(colors: [.black.opacity(0.7), .clear]), startPoint: .bottom, endPoint: .top)
                            )
                            .cornerRadius(16)
                        }
                        .frame(height: 140)
                    }

                    // Upcoming Events
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📅 Upcoming Events")
                            .font(.headline)
                        VStack(spacing: 12) {
                            EventCard(title: "Amsterdam Student Night", date: "May 5, 2025 • 21:00", tag: "Smart Casual", price: "€5")
                            EventCard(title: "TU Delft Spring Party", date: "May 7, 2025 • 22:00", tag: "Casual", price: "€10")
                        }
                    }

                    // Map Section (Placeholder)
                    Image("map_placeholder")
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .cornerRadius(16)
                        .frame(height: 120)

                    // Host Your Own Party
                    VStack(alignment: .leading, spacing: 8) {
                        Text("✨ Host your own party?")
                            .font(.headline)
                        Text("Create and manage your event with ease")
                            .font(.subheadline)
                        Button(action: {}) {
                            Text("Create Party")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(gradient: Gradient(colors: [.purple, .pink]), startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(16)
                }
                .padding(.horizontal)
            }
            .background(Color.white)

            // Bottom Navigation Bar
            HStack {
                NavBarItem(icon: "house.fill", label: "Home", selected: true)
                NavBarItem(icon: "ticket.fill", label: "Tickets")
                NavBarItem(icon: "calendar", label: "Events")
                NavBarItem(icon: "bubble.left.and.bubble.right", label: "Chat")
                NavBarItem(icon: "person.crop.circle", label: "Profile")
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
}

struct EventCard: View {
    var title: String
    var date: String
    var tag: String
    var price: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).bold()
                Text(date).font(.caption)
                HStack {
                    Text(tag)
                        .font(.caption2)
                        .padding(4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    Text(price)
                        .font(.caption2)
                        .padding(4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            Spacer()
            Button("Join") {}
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

struct NavBarItem: View {
    var icon: String
    var label: String
    var selected: Bool = false

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(selected ? .purple : .gray)
            Text(label)
                .font(.caption)
                .foregroundColor(selected ? .purple : .gray)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomePage()
}