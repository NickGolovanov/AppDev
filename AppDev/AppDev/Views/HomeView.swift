import MapKit
import SwiftUI
import FirebaseFirestore

class HomeViewModel: ObservableObject {
    @Published var upcomingEvents: [Event] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func fetchEvents() {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        db.collection("events")
            .order(by: "createdAt", descending: true)
            .limit(to: 5) // Limit to 5 events for the home page
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "Failed to load events: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.errorMessage = "No events found."
                        return
                    }
                    
                    self?.upcomingEvents = documents.compactMap { doc in
                        let data = doc.data()
                        let id = doc.documentID
                        
                        guard let title = data["title"] as? String,
                              let date = data["date"] as? String,
                              let location = data["location"] as? String,
                              let imageUrl = data["imageUrl"] as? String,
                              let attendees = data["attendees"] as? Int,
                              let category = data["category"] as? String,
                              let price = data["price"] as? Double else {
                            return nil
                        }
                        
                        return Event(
                            id: id,
                            title: title,
                            date: date,
                            location: location,
                            coordinate: nil,
                            imageUrl: imageUrl,
                            attendees: attendees,
                            distance: nil,
                            category: category,
                            price: price
                        )
                    }
                }
            }
    }
}

struct Event: Identifiable {
    let id: String
    let title: String
    let date: String
    let location: String
    let coordinate: CLLocationCoordinate2D?
    let imageUrl: String
    let attendees: Int
    let distance: String?
    let category: String
    let price: Double
}

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
            }
        }
    }

    func trendingCard(event: Event) -> some View {
        let cardWidth = UIScreen.main.bounds.width * 0.7
        return NavigationLink(destination: EventView(eventId: event.id)) {
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
                    Text(event.date)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
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
    }

    func eventCard(event: Event) -> some View {
        return HStack {
            VStack(alignment: .leading) {
                Text(event.title)
                    .font(.headline)
                Text(event.date)
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
            NavigationLink(destination: EventView(eventId: event.id)) {
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
