import MapKit
import SwiftUI
import Foundation

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    HeaderView()
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Trending Tonight
                    Text("🔥 Trending Tonight")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.upcomingEvents) {event in
                                trendingCard(
                                    title: event.title,
                                    subtitle: event.date,
                                    category: event.category,
                                    imageUrl: event.imageUrl,
                                ) 
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.leading, 20)
                    }
                    .frame(height: 130)
                    Spacer(minLength: 20)  //space between the scroll view and the upcoming events

                    // Upcoming Events
                    Text("🗓️ Upcoming Events")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 15) {
                        ForEach(viewModel.upcomingEvents) { event in 
                            eventCard(
                                name: event.title,
                                date: event.subtitle,
                                category: event.category,
                                price: "€\(event.price ?? 0)"
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Map
                    ZStack(alignment: .bottomTrailing) {
                        Image("map")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 370, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Image(systemName: "location.circle.fill")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.purple)
                            .background(Color.white)
                            .clipShape(Circle())
                            .padding(20)
                    }
                    .frame(width: 370, height: 150)
                    .padding(.horizontal)

                    // Host Party Section
                    hostPartyCard()
                        .padding(.horizontal)
                        .padding(.bottom, 80)
                }
                .padding(.top)
            }
            .onAppear {
                viewModel.fetchEvents()
            }
        }
    }

    func trendingCard(
        title: String, subtitle: String, category: String, imageUrl: String
    ) -> some View {
        let cardWidth = UIScreen.main.bounds.width * 0.7
        return NavigationLink(destination: EventView()) {
            VStack(alignment: .leading, spacing: 0) {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray
                }
                .aspectRatio(contentMode: .fill)
                .frame(width: cardWidth, height: 80)
                .clipped()
                .cornerRadius(10, corners: [.topLeft, .topRight])

                VStack(alignment: .leading, spacing: 4) {
                    Text(category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(5)
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
            .background(Color.purple)
            .cornerRadius(12)
        }
    }

    func eventCard(name: String, date: String, dressCode: String, price: String) -> some View {
        return HStack {
            VStack(alignment: .leading) {
                Text(name).font(.headline)
                Text(date).font(.caption).foregroundColor(.gray)
                HStack {
                    Text(dressCode).font(.caption2).padding(4).background(
                        Color.purple.opacity(0.2)
                    )
                    .cornerRadius(4)
                    Text(price).font(.caption2).padding(4).background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            Spacer()
            NavigationLink(destination: EventView()) {
                Text("Join")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
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
        NavigationLink(destination: CreateEventView()) {
            Text("Create Party")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
                .foregroundColor(.purple)
                .cornerRadius(10)
        }
    }
    .padding()
    .background(
        LinearGradient(
            colors: [Color.purple, Color.pink], startPoint: .leading, endPoint: .trailing)
    )
    .cornerRadius(15)
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

#Preview {
    HomeView()
}
