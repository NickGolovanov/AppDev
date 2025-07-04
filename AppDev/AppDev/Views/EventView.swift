import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EventView: View {
    let eventId: String
    @State private var event: Event? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showGetTicket = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var hasJoinedEvent: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    // Review-related states
    @StateObject private var reviewService = ReviewService()
    @State private var reviews: [Review] = []
    @State private var showCreateReview = false
    @State private var canReview = false
    @State private var hasReviewed = false
    @State private var isCheckingReviewStatus = false
    @State private var isLoadingReviews = false
    
    // Recommendation service for tracking
    @StateObject private var recommendationService = RecommendationService()

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
                .padding(.horizontal)
                .padding(.bottom, 8)

            if isLoading {
                ProgressView().padding()
            } else if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red).padding()
            } else if let event = event {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ZStack(alignment: .topLeading) {
                            // Event Image
                            if let imageUrl = URL(string: event.imageUrl) {
                                AsyncImage(url: imageUrl) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 240)
                                        .clipped()
                                } placeholder: {
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(height: 240)
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
                                    .frame(height: 240)
                            }

                            // Back and Favorite buttons
                            HStack {
                                Button(action: {
                                    dismiss()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }

                        // Event Card
                        VStack(alignment: .leading, spacing: 24) {
                            // Title
                            Text(event.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.top, 8)

                            // Date, Time, Location
                            VStack(spacing: 12) {
                                HStack(alignment: .center, spacing: 8) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.purple)
                                        .font(.system(size: 16))
                                    Text("\(event.formattedDate) · \(event.formattedTime)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                HStack(alignment: .center, spacing: 8) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.purple)
                                        .font(.system(size: 16))
                                    Text(event.location)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }

                            // About Event
                            VStack(alignment: .leading, spacing: 12) {
                                Text("About Event")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(event.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineSpacing(4)
                            }

                            // People Attending
                            VStack(alignment: .leading, spacing: 12) {
                                Text("People Attending")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                HStack(spacing: 8) {
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(.purple)
                                        .font(.system(size: 16))
                                    Text("\(event.attendees) going")
                                        .font(.subheadline)
                                        .foregroundColor(.purple)
                                }
                            }

                            // Price and Tickets
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Price per ticket")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("€\(String(format: "%.2f", event.price))")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Available tickets")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(event.maxCapacity - event.attendees) left")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Reviews Section - NEW ADDITION
                            reviewsSummarySection
                            
                            // Get Ticket Button
                            if hasJoinedEvent {
                                Text("You've already joined")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray)
                                    .cornerRadius(12)
                                    .padding(.top, 8)
                            } else {
                                let getTicketDestination = getTicketDestination
                                NavigationLink(destination: getTicketDestination, isActive: $showGetTicket) {
                                    EmptyView()
                                }
                                Button(action: {
                                    showGetTicket = true
                                    // Track ticket purchase intent
                                    recommendationService.trackUserAction(eventId: eventId, actionType: .clicked, event: event)
                                }) {
                                    Text("Get Ticket Now")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                }
                                .padding(.top, 8)
                                .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            // REVIEWS SECTION
                            reviewsSection
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color(.systemGray4), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 8)
                        .offset(y: -40)
                    }
                }
                .background(Color(.systemGray6).ignoresSafeArea())
            }
        }
        .navigationTitle(event?.title ?? "Event")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: fetchEvent)
        .navigationBarHidden(true)
        .sheet(isPresented: $showCreateReview) {
            if let event = event {
                CreateReviewView(event: event, onReviewCreated: {
                    fetchReviews()
                    Task { await checkReviewStatus() }
                    // Track review action
                    recommendationService.trackUserAction(eventId: eventId, actionType: .rated, event: event)
                })
            }
        }
        .task {
            if let event = event {
                await checkReviewStatus()
                fetchReviews()
            }
        }
    }
    
    // Reviews Summary Section - NEW
    @ViewBuilder
    private var reviewsSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Reviews Section Header
            HStack {
                Image(systemName: "star.bubble.fill")
                    .foregroundColor(.purple)
                Text("Event Reviews")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if let totalReviews = event?.totalReviews, totalReviews > 0 {
                    Text("\(totalReviews) review\(totalReviews == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Reviews Summary Preview
            if let averageRating = event?.averageRating, 
               let totalReviews = event?.totalReviews, 
               totalReviews > 0 {
                
                HStack {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(averageRating.rounded()) ? "star.fill" : "star")
                                .foregroundColor(.purple)
                                .font(.caption)
                        }
                    }
                    Text(String(format: "%.1f", averageRating))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("• \(totalReviews) review\(totalReviews == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                
                // View All Reviews Button
                NavigationLink(destination: EventReviewsView(eventId: eventId)) {
                    HStack {
                        Text("View All Reviews & Comments")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(8)
                }
            } else {
                Text("No reviews yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(12)
    }
    
    // Reviews Section View
    @ViewBuilder
    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .padding(.vertical, 8)
            
            HStack {
                Text("Recent Reviews")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                
                // Show average rating if available
                if let rating = event?.averageRating, rating > 0 {
                    HStack(spacing: 4) {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= Int(rating.rounded()) ? "star.fill" : "star")
                                    .foregroundColor(.purple)
                                    .font(.caption)
                            }
                        }
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("(\(event?.totalReviews ?? 0))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Write Review Button (for ended events you attended)
            if let event = event, event.hasEnded && canReview && !hasReviewed && !isCheckingReviewStatus {
                Button(action: {
                    showCreateReview = true
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Write a Review")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            // Loading state for review check
            if isCheckingReviewStatus {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Checking review status...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Reviews List
            if isLoadingReviews {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading reviews...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
            } else if reviews.isEmpty {
                Text("No reviews yet")
                    .foregroundColor(.gray)
                    .italic()
                    .padding()
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(reviews.prefix(3), id: \.id) { review in // Show only first 3 reviews
                        ReviewRowView(review: review)
                    }
                    
                    // Show "View All" button if there are more than 3 reviews
                    if reviews.count > 3 {
                        NavigationLink(destination: EventReviewsView(eventId: eventId)) {
                            HStack {
                                Text("View All \(reviews.count) Reviews")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    func fetchEvent() {
        isLoading = true
        errorMessage = nil
        let db = Firestore.firestore()
        db.collection("events").document(eventId).getDocument { snapshot, error in
            isLoading = false
            if let error = error {
                errorMessage = "Failed to load event: \(error.localizedDescription)"
                return
            }
            guard let document = snapshot, document.exists else {
                errorMessage = "Event not found."
                return
            }
            self.event = try? document.data(as: Event.self)
            if self.event != nil {
                checkIfUserJoinedEvent()
                Task {
                    await checkReviewStatus()
                    fetchReviews()
                }
            } else {
                errorMessage = "Failed to decode event."
            }
        }
    }

    func checkIfUserJoinedEvent() {
        guard let userId = authViewModel.currentUser?.id else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, _ in
            if let document = document, document.exists {
                if let joinedEventIds = document.data()?["joinedEventIds"] as? [String] {
                    DispatchQueue.main.async {
                        self.hasJoinedEvent = joinedEventIds.contains(self.eventId)
                        
                        // Track attendance behavior if user has joined
                        if self.hasJoinedEvent, let event = self.event {
                            self.recommendationService.trackUserAction(eventId: self.eventId, actionType: .attended, event: event)
                        }
                    }
                }
            }
        }
    }

    var getTicketDestination: some View {
        if let event = event {
            return AnyView(GetTicketView(event: event))
        } else {
            return AnyView(EmptyView())
        }
    }
    
    // Review Functions
    private func checkReviewStatus() async {
        guard let event = event,
              let eventId = event.id,
              !eventId.isEmpty,
              event.hasEnded,
              let userId = Auth.auth().currentUser?.uid,
              !userId.isEmpty else {
            return
        }
        
        DispatchQueue.main.async {
            self.isCheckingReviewStatus = true
        }
        
        do {
            let userHasReviewed = try await reviewService.checkIfUserReviewed(eventId: eventId, userId: userId)
            
            // Check if user attended the event (has a ticket)
            let db = Firestore.firestore()
            let ticketsQuery = db.collection("tickets")
                .whereField("eventId", isEqualTo: eventId)
                .whereField("userId", isEqualTo: userId)
                .whereField("status", isEqualTo: "active")
            
            let ticketSnapshot = try await ticketsQuery.getDocuments()
            let userAttended = !ticketSnapshot.isEmpty
            
            DispatchQueue.main.async {
                self.hasReviewed = userHasReviewed
                self.canReview = userAttended && !userHasReviewed
                self.isCheckingReviewStatus = false
            }
            
        } catch {
            print("Error checking review status: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.canReview = false
                self.isCheckingReviewStatus = false
            }
        }
    }

    private func fetchReviews() {
        guard let eventId = event?.id else { return }
        
        isLoadingReviews = true
        
        let db = Firestore.firestore()
        db.collection("reviews")
            .whereField("eventId", isEqualTo: eventId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoadingReviews = false
                    
                    if let error = error {
                        print("Error fetching reviews: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.reviews = []
                        return
                    }
                    
                    self.reviews = documents.compactMap { doc in
                        try? doc.data(as: Review.self)
                    }
                }
            }
    }
}

struct ReviewRowView: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Anonymous display
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("A")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Anonymous Reviewer")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(review.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Show overall rating prominently
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= Int(review.overallRating) ? "star.fill" : "star")
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                    Text(String(format: "%.1f", review.overallRating))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Detailed ratings section
            HStack(spacing: 16) {
                ratingPill("Music", rating: review.musicRating, color: .blue)
                ratingPill("Location", rating: review.locationRating, color: .green)
                ratingPill("Vibe", rating: review.vibeRating, color: .pink)
            }
            
            // Comment section - ENHANCED
            if !review.comment.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "quote.bubble.fill")
                            .foregroundColor(.purple)
                            .font(.caption)
                        Text("Feedback")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                        Spacer()
                    }
                    
                    Text("\"\(review.comment)\"")
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.purple.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func ratingPill(_ title: String, rating: Double, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
            Text(String(format: "%.0f", rating))
                .font(.caption2)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(6)
    }
}

#Preview {
    EventView(eventId: "someEventId")
        .environmentObject(AuthViewModel())
}