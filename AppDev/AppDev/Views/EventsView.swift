import MapKit
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EventsView: View {
    @State private var selectedFilter = "All Events"
    @State private var showCreateEvent = false
    @State private var searchText = ""
    
    // Add recommendation service
    @StateObject private var recommendationService = RecommendationService()
    
    let filters = [
        "All Events",
        "For You", // New personalized tab
        "House Party",
        "Concert",
        "Meetup",
        "Workshop",
        "Conference",
        "Exhibition",
        "Festival",
        "Food & Drink",
        "Sports",
        "Theater",
        "Comedy",
        "Networking",
        "Art Gallery",
        "Music Festival",
        "Charity Event",
        "Business Event",
        "Cultural Event",
        "Educational",
        "Fashion Show",
        "Gaming Event"
    ]
    @State private var events: [Event] = []
    @State private var filteredEvents: [Event] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 0) {
                        HeaderView()
                            .padding(.horizontal)
                            .padding(.bottom, 8)

                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search events...", text: $searchText)
                                .onChange(of: searchText) { _ in
                                    filterEvents()
                                }
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
                                    HStack(spacing: 4) {
                                        // Add special icon for "For You" tab
                                        if filter == "For You" {
                                            Image(systemName: "sparkles")
                                                .font(.caption)
                                                .foregroundColor(selectedFilter == filter ? .purple : .black)
                                        }
                                        
                                        Text(filter)
                                            .font(.subheadline)
                                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedFilter == filter
                                            ? (filter == "For You" ? Color.orange.opacity(0.2) : Color.purple.opacity(0.2))
                                            : Color(.systemGray5)
                                    )
                                    .foregroundColor(
                                        selectedFilter == filter 
                                            ? (filter == "For You" ? .orange : .purple) 
                                            : .black
                                    )
                                    .cornerRadius(20)
                                    .onTapGesture { 
                                        selectedFilter = filter
                                        filterEvents()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 8)

                        // Content based on selected filter
                        if selectedFilter == "For You" {
                            // Personalized recommendations view
                            personalizedRecommendationsView
                        } else {
                            // Regular events view
                            regularEventsView
                        }

                        Spacer()
                    }
                }
                // Floating Action Button (FAB) always visible above the tab bar
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
                .padding(.bottom, 80) // Adjust this value to sit above the tab bar/footer
            }
            .background(Color.white.ignoresSafeArea())
            .navigationDestination(isPresented: $showCreateEvent) {
                CreateEventView()
            }
        }
        .onAppear {
            fetchEvents()
            // Generate recommendations when view appears
            Task {
                await recommendationService.generateRecommendations()
            }
        }
    }
    
    // MARK: - Personalized Recommendations View
    var personalizedRecommendationsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if Auth.auth().currentUser == nil {
                // Not logged in message
                VStack(spacing: 16) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Sign in to see personalized recommendations")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("We'll learn your preferences and suggest events you'll love!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .frame(maxWidth: .infinity)
            } else if recommendationService.isLoading {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Finding events you'll love...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(40)
                .frame(maxWidth: .infinity)
            } else if recommendationService.recommendedEvents.isEmpty {
                // No recommendations yet
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Building your recommendations")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("Interact with events to help us learn your preferences!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    // Show some popular events as fallback
                    Button("Show Popular Events") {
                        selectedFilter = "All Events"
                        filterEvents()
                    }
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                }
                .padding(40)
                .frame(maxWidth: .infinity)
            } else {
                // Show recommendations
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.orange)
                        Text("Recommended for You")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                    
                    Text("Based on your preferences and activity")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    ForEach(recommendationService.recommendedEvents) { event in
                        RecommendedEventView(event: event, recommendationService: recommendationService)
                    }
                }
                .padding(.top, 8)
            }
            
            if let error = recommendationService.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            if Auth.auth().currentUser != nil {
                Button("🔍 Debug Recommendations") {
                    Task {
                        await recommendationService.debugUserPreferences()
                        await recommendationService.generateRecommendations()
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Regular Events View
    var regularEventsView: some View {
        VStack(spacing: 0) {
            // Featured Event
            if let firstEvent = filteredEvents.first {
                FeaturedEventView(event: firstEvent, recommendationService: recommendationService)
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
                    ForEach(filteredEvents) { event in
                        UpcomingEventView(event: event, recommendationService: recommendationService)
                    }
                }
            }
            .padding(.top, 8)
        }
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
                      let endTime = data["endTime"] as? String,
                      let startTime = data["startTime"] as? String,
                      let location = data["location"] as? String,
                      let imageUrl = data["imageUrl"] as? String,
                      let attendees = data["attendees"] as? Int,
                      let maxCapacity = data["maxCapacity"] as? Int,
                      let description = data["description"] as? String
                else {
                    return nil
                }
                let latitude = data["latitude"] as? Double
                let longitude = data["longitude"] as? Double
                let category = data["category"] as? String ?? "Other"
                let price = data["price"] as? Double ?? 0.0
                let averageRating = data["averageRating"] as? Double
                let totalReviews = data["totalReviews"] as? Int
                
                return Event(
                    id: id,
                    title: title,
                    date: date,
                    endTime: endTime,
                    startTime: startTime,
                    location: location,
                    imageUrl: imageUrl,
                    attendees: attendees,
                    category: category,
                    price: price,
                    maxCapacity: maxCapacity,
                    description: description,
                    latitude: latitude,
                    longitude: longitude,
                    averageRating: averageRating,
                    totalReviews: totalReviews
                )
            }
            filterEvents()
        }
    }

    private func filterEvents() {
        // Skip filtering for "For You" tab as it uses recommendations
        if selectedFilter == "For You" {
            return
        }
        
        var filtered = events
        
        // Apply category filter
        if selectedFilter != "All Events" {
            filtered = filtered.filter { $0.category == selectedFilter }
        }
        
        // Apply search filter if search text is not empty
        if !searchText.isEmpty {
            filtered = filtered.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText) ||
                event.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredEvents = filtered
    }
}

// MARK: - Recommended Event View Component
struct RecommendedEventView: View {
    let event: Event
    let recommendationService: RecommendationService
    
    var body: some View {
        NavigationLink(destination: EventView(eventId: event.id ?? "-1")) {
            HStack(spacing: 16) {
                // Event Image
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
                                    gradient: Gradient(colors: [Color.orange.opacity(0.7), Color.pink.opacity(0.5)]),
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
                                gradient: Gradient(colors: [Color.orange.opacity(0.7), Color.pink.opacity(0.5)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Event Title with "FOR YOU" badge
                    HStack {
                        Text(event.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Text("FOR YOU")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("\(event.formattedDate)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("\(event.formattedTime)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(event.location)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text(event.category)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                            
                            Text("€\(String(format: "%.0f", event.price))")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                        
                        // Display rating if available
                        if let rating = event.averageRating, rating > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption2)
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.orange)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.05), Color.pink.opacity(0.02)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
        .onTapGesture {
            // Track recommendation click
            if let eventId = event.id {
                recommendationService.trackUserAction(eventId: eventId, actionType: .clicked, event: event)
            }
        }
    }
}

struct FeaturedEventView: View {
    let event: Event
    let recommendationService: RecommendationService

    var body: some View {
        NavigationLink(destination: EventView(eventId: event.id ?? "-1")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Featured Event")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .foregroundColor(.primary)

                ZStack(alignment: .bottomLeading) {
                    if let imageUrl = URL(string: event.imageUrl) {
                        AsyncImage(url: imageUrl) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        }
                        .frame(height: 200)
                        .cornerRadius(16)
                    }

                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), .clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 200)
                    .cornerRadius(16)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(2)

                        HStack {
                            Text(event.formattedDate)
                            Text(event.formattedTime)
                            Text("•")
                            Text(event.location)
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .font(.subheadline)
                        
                        // Display rating if available
                        if let rating = event.averageRating, rating > 0 {
                            HStack(spacing: 4) {
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= Int(rating.rounded()) ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                    }
                                }
                                Text("(\(event.totalReviews ?? 0))")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding(16)
                }
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 8)
        }
        .onTapGesture {
            // Track featured event click
            if let eventId = event.id {
                recommendationService.trackUserAction(eventId: eventId, actionType: .clicked, event: event)
            }
        }
    }
}

struct UpcomingEventView: View {
    let event: Event
    let recommendationService: RecommendationService
    
    var body: some View {
        NavigationLink(destination: EventView(eventId: event.id ?? "-1")) {
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
                        Text("\(event.formattedDate)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("\(event.formattedTime)")
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
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.purple)
                                .font(.caption)
                            Text("\(event.attendees) going")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                        
                        // Display rating if available
                        if let rating = event.averageRating, rating > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption2)
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("(\(event.totalReviews ?? 0))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Spacer()
                
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
        .onTapGesture {
            // Track upcoming event click
            if let eventId = event.id {
                recommendationService.trackUserAction(eventId: eventId, actionType: .clicked, event: event)
            }
        }
    }
}

#Preview {
    EventsView()
}