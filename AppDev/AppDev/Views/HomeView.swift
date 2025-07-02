import MapKit
import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var recommendationService = RecommendationService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HeaderView()
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Recommended for You Section
                    if !recommendationService.recommendedEvents.isEmpty {
                        Text("✨ Recommended for You")
                            .font(.headline)
                            .padding(.horizontal)

                        if recommendationService.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(height: 130)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(recommendationService.recommendedEvents) { event in
                                        recommendedCard(event: event)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.leading, 20)
                            }
                            .frame(height: 150)
                        }
                        Spacer(minLength: 20)
                    }

                    // Trending Tonight
                    Text("🔥 Trending Tonight")
                        .font(.headline)
                        .padding(.horizontal)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(height: 130)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(height: 130)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.upcomingEvents) { event in
                                    trendingCard(event: event)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.leading, 20)
                        }
                        .frame(height: 130)
                    }
                    Spacer(minLength: 20)

                    // Upcoming Events
                    Text("🗓️ Upcoming Events")
                        .font(.headline)
                        .padding(.horizontal)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        VStack(spacing: 15) {
                            ForEach(viewModel.upcomingEvents) { event in
                                eventCard(event: event)
                            }
                        }
                        .padding(.horizontal)
                    }

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
                Task {
                    await recommendationService.generateRecommendations()
                }
            }
        }
    }

    func recommendedCard(event: Event) -> some View {
        let cardWidth = UIScreen.main.bounds.width * 0.8
        return NavigationLink(destination: EventView(eventId: event.id ?? "-1")) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    if let imageUrl = URL(string: event.imageUrl) {
                        AsyncImage(url: imageUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: cardWidth, height: 100)
                                .clipped()
                                .cornerRadius(10, corners: [.topLeft, .topRight])
                        } placeholder: {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.orange.opacity(0.7), Color.pink.opacity(0.5)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: cardWidth, height: 100)
                                .cornerRadius(10, corners: [.topLeft, .topRight])
                        }
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange.opacity(0.7), Color.pink.opacity(0.5)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: cardWidth, height: 100)
                            .cornerRadius(10, corners: [.topLeft, .topRight])
                    }
                    
                    // "For You" badge
                    Text("FOR YOU")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                        .padding(8)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(event.category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(5)
                        
                        if let rating = event.averageRating, rating > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption2)
                                Text(String(format: "%.1f", rating))
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text("\(event.formattedDate), \(event.formattedTime)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(12)
                .frame(width: cardWidth, alignment: .leading)
            }
            .frame(width: cardWidth)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.pink.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.orange.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .onTapGesture {
            // Track recommendation click
            if let eventId = event.id {
                recommendationService.trackUserAction(eventId: eventId, actionType: .clicked, event: event)
            }
        }
    }

    func trendingCard(event: Event) -> some View {
        let cardWidth = UIScreen.main.bounds.width * 0.7
        return NavigationLink(destination: EventView(eventId: event.id ?? "-1")) {
            VStack(alignment: .leading, spacing: 0) {
                if let imageUrl = URL(string: event.imageUrl) {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: cardWidth, height: 80)
                            .clipped()
                            .cornerRadius(10, corners: [.topLeft, .topRight])
                    } placeholder: {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: cardWidth, height: 80)
                            .cornerRadius(10, corners: [.topLeft, .topRight])
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
                        .frame(width: cardWidth, height: 80)
                        .cornerRadius(10, corners: [.topLeft, .topRight])
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(event.formattedDate), \(event.formattedTime)")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(8)
                .frame(width: cardWidth, alignment: .leading)
            }
            .frame(width: cardWidth)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
        }
        .onTapGesture {
            // Track click behavior
            if let eventId = event.id {
                recommendationService.trackUserAction(eventId: eventId, actionType: .clicked, event: event)
            }
        }
    }

    func eventCard(event: Event) -> some View {
        return HStack {
            VStack(alignment: .leading) {
                Text(event.title)
                    .font(.headline)
                Text("\(event.formattedDate), \(event.formattedTime)")
                    .font(.caption)
                    .foregroundColor(.gray)
                HStack {
                    Text(event.category)
                        .font(.caption2)
                        .padding(4)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(4)
                    Text("€\(String(format: "%.2f", event.price))")
                        .font(.caption2)
                        .padding(4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            Spacer()
            NavigationLink(destination: EventView(eventId: event.id ?? "-1")) {
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
        .onTapGesture {
            // Track click behavior
            if let eventId = event.id {
                recommendationService.trackUserAction(eventId: eventId, actionType: .clicked, event: event)
            }
        }
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