import SwiftUI
import FirebaseFirestore

struct EventView: View {
    let eventId: String
    @State private var event: Event? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showGetTicket = false
    @State private var showRatingView = false
    @State private var showRatingsView = false
    @State private var userHasRated = false
    @State private var isEventOrganizer = false
    @State private var averageRating: Double? = nil
    @State private var totalRatings: Int = 0
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var hasJoinedEvent: Bool = false
    @Environment(\.dismiss) private var dismiss

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
                            // Title and Rating
                            VStack(alignment: .leading, spacing: 8) {
                                Text(event.title)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.top, 8)
                                
                                // Show rating if available
                                if let averageRating = averageRating, totalRatings > 0 {
                                    HStack(spacing: 8) {
                                        HStack(spacing: 2) {
                                            ForEach(1...5, id: \.self) { star in
                                                Image(systemName: Double(star) <= averageRating ? "star.fill" : "star")
                                                    .font(.caption)
                                                    .foregroundColor(.yellow)
                                            }
                                        }
                                        Text(String(format: "%.1f", averageRating))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("(\(totalRatings) reviews)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        if isEventOrganizer {
                                            Button("View All") {
                                                showRatingsView = true
                                            }
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }

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

                            // Action Buttons
                            VStack(spacing: 12) {
                                if hasJoinedEvent {
                                    Text("You've already joined")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray)
                                        .cornerRadius(12)
                                        .padding(.top, 8)
                                    
                                    // Show rating button if event has passed and user hasn't rated
                                    if canUserRate {
                                        Button(action: {
                                            showRatingView = true
                                        }) {
                                            HStack {
                                                Image(systemName: userHasRated ? "checkmark.circle.fill" : "star.fill")
                                                Text(userHasRated ? "Rating Submitted" : "Rate This Event")
                                            }
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(userHasRated ? Color.green : Color.orange)
                                            .cornerRadius(12)
                                        }
                                        .disabled(userHasRated)
                                    }
                                } else {
                                    let getTicketDestination = getTicketDestination
                                    NavigationLink(destination: getTicketDestination, isActive: $showGetTicket) {
                                        EmptyView()
                                    }
                                    Button(action: {
                                        showGetTicket = true
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
                            }
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
        .onAppear {
            fetchEvent()
            fetchEventRatings()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showRatingView) {
            if let event = event {
                RatingView(eventId: eventId, eventTitle: event.title)
                    .onDisappear {
                        // Refresh ratings after submitting
                        checkIfUserHasRated()
                        fetchEventRatings()
                    }
            }
        }
        .sheet(isPresented: $showRatingsView) {
            if let event = event {
                EventRatingsView(eventId: eventId, eventTitle: event.title)
            }
        }
    }
    
    private var canUserRate: Bool {
        // User can rate if:
        // 1. They joined the event
        // 2. The event has passed (you might need to add event date comparison)
        // 3. They haven't rated yet
        // For now, just check if they joined and haven't rated
        return hasJoinedEvent && !userHasRated && isEventPassed
    }
    
    private var isEventPassed: Bool {
        // You'll need to implement this based on your Event model's date properties
        // This is a placeholder - implement according to your date format
        guard let event = event else { return false }
        // Assuming you have a way to check if event date has passed
        // return event.date < Date()
        return true // Placeholder - implement based on your Event model
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
                checkIfUserIsOrganizer()
                checkIfUserHasRated()
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
                    }
                }
            }
        }
    }
    
    func checkIfUserIsOrganizer() {
        guard let userId = authViewModel.currentUser?.id else { return }
        guard let event = event else { return }
        
        DispatchQueue.main.async {
            self.isEventOrganizer = event.organizerId == userId
        }
    }
    
    func checkIfUserHasRated() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        let db = Firestore.firestore()
        db.collection("ratings")
            .whereField("eventId", isEqualTo: eventId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.userHasRated = !(snapshot?.documents.isEmpty ?? true)
                }
            }
    }
    
    func fetchEventRatings() {
        let db = Firestore.firestore()
        db.collection("ratings")
            .whereField("eventId", isEqualTo: eventId)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                if documents.isEmpty {
                    DispatchQueue.main.async {
                        self.averageRating = nil
                        self.totalRatings = 0
                    }
                    return
                }
                
                let ratings = documents.compactMap { doc -> Rating? in
                    try? doc.data(as: Rating.self)
                }
                
                let totalMusic = ratings.map(\.musicRating).reduce(0, +)
                let totalLocation = ratings.map(\.locationRating).reduce(0, +)
                let totalVibe = ratings.map(\.vibeRating).reduce(0, +)
                let count = ratings.count
                
                let avgMusic = Double(totalMusic) / Double(count)
                let avgLocation = Double(totalLocation) / Double(count)
                let avgVibe = Double(totalVibe) / Double(count)
                let overallAverage = (avgMusic + avgLocation + avgVibe) / 3.0
                
                DispatchQueue.main.async {
                    self.averageRating = overallAverage
                    self.totalRatings = count
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
}

#Preview {
    EventView(eventId: "someEventId")
        .environmentObject(AuthViewModel())
}