import FirebaseFirestore
import FirebaseAuth
import Foundation

class RecommendationService: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var recommendedEvents: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func trackUserAction(eventId: String, actionType: UserBehavior.ActionType, event: Event? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
    
        let behavior = UserBehavior(
            userId: userId,
            eventId: eventId,
            actionType: actionType,
            timestamp: Date(),
            eventCategory: event?.category,
            eventPrice: event?.price,
            eventLocation: event?.location
        )
    
        do {
            try db.collection("userBehavior").addDocument(from: behavior) { error in
                if let error = error {
                    print("Error saving behavior: \(error)")
                }
            }
        
            Task {
                await updateUserPreferences(userId: userId, behavior: behavior)
            }
        } catch {
            print("Error tracking user behavior: \(error)")
        }
    }
    
    // MARK: - Update User Preferences
    private func updateUserPreferences(userId: String, behavior: UserBehavior) async {
        do {
            let preferencesRef = db.collection("userPreferences").document(userId)
            let document = try await preferencesRef.getDocument()
            
            var preferences: UserPreferences
            if document.exists {
                preferences = try document.data(as: UserPreferences.self)
                print("Existing preferences found")
            } else {
                preferences = UserPreferences(userId: userId)
                print(" Creating new preferences")
            }
            
            // Update preferences based on behavior
            updatePreferencesWithBehavior(&preferences, behavior: behavior)
            
            // Save updated preferences
            try preferencesRef.setData(from: preferences)
            print("✅ Updated preferences - Categories: \(preferences.preferredCategories)")
            
        } catch {
            print("❌ Error updating user preferences: \(error)")
        }
    }
    
    private func updatePreferencesWithBehavior(_ preferences: inout UserPreferences, behavior: UserBehavior) {
        let weight = getActionWeight(behavior.actionType)
        
        // Update category preferences
        if let category = behavior.eventCategory {
            let currentWeight = preferences.preferredCategories[category] ?? 0
            preferences.preferredCategories[category] = currentWeight + weight
            print(" Updated category '\(category)': \(currentWeight) -> \(currentWeight + weight)")
        }
        
        // Update location preferences
        if let location = behavior.eventLocation {
            let currentWeight = preferences.preferredLocations[location] ?? 0
            preferences.preferredLocations[location] = currentWeight + weight
            print(" Updated location '\(location)': \(currentWeight) -> \(currentWeight + weight)")
        }
        
        // Update time preferences (simplified - using hour of day)
        let hour = Calendar.current.component(.hour, from: behavior.timestamp)
        let timeSlot = getTimeSlot(hour: hour)
        let currentTimeWeight = preferences.preferredTimes[timeSlot] ?? 0
        preferences.preferredTimes[timeSlot] = currentTimeWeight + weight
        
        preferences.lastUpdated = Date()
    }
    
    private func getActionWeight(_ actionType: UserBehavior.ActionType) -> Double {
        switch actionType {
        case .attended: return 5.0
        case .purchased: return 4.0
        case .rated: return 3.0
        case .saved: return 2.0
        case .shared: return 1.5
        case .clicked: return 1.0
        }
    }
    
    private func getTimeSlot(hour: Int) -> String {
        switch hour {
        case 6..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<22: return "evening"
        default: return "night"
        }
    }
    
    // MARK: - Generate Recommendations
    func generateRecommendations() async {
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("No user ID for recommendations")
            return 
        }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let preferences = try await getUserPreferences(userId: userId)
            let allEvents = try await getAllEvents()
            let availableEvents = try await filterUserEvents(allEvents, userId: userId)

            if availableEvents.isEmpty {
                DispatchQueue.main.async {
                    self.recommendedEvents = []
                    self.isLoading = false
                }
                return
            }

            let scoredEvents = scoreEvents(availableEvents, preferences: preferences, userId: userId)
            let recommendations = Array(scoredEvents.prefix(10))

            DispatchQueue.main.async {
                self.recommendedEvents = recommendations
                self.isLoading = false
            }

        } catch {
            print("Error generating recommendations: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to generate recommendations: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func getUserPreferences(userId: String) async throws -> UserPreferences {
        let document = try await db.collection("userPreferences").document(userId).getDocument()
        
        if document.exists {
            let preferences = try document.data(as: UserPreferences.self)
            print(" Loaded preferences: \(preferences.preferredCategories)")
            return preferences
        } else {
            print(" No preferences found, creating from behavior")
            // Create default preferences based on user behavior
            return try await createDefaultPreferences(userId: userId)
        }
    }
    
    private func createDefaultPreferences(userId: String) async throws -> UserPreferences {
        print(" Analyzing user behavior for initial preferences")
        
        // Analyze user's past behavior to create initial preferences
        let behaviorQuery = db.collection("userBehavior")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
        
        let behaviorSnapshot = try await behaviorQuery.getDocuments()
        let behaviors = behaviorSnapshot.documents.compactMap { try? $0.data(as: UserBehavior.self) }
        
        print(" Found \(behaviors.count) past behaviors")
        
        var preferences = UserPreferences(userId: userId)
        
        // Analyze behaviors to set initial preferences
        for behavior in behaviors {
            updatePreferencesWithBehavior(&preferences, behavior: behavior)
            print("  - \(behavior.actionType): \(behavior.eventCategory ?? "Unknown")")
        }
        
        // Save preferences
        try db.collection("userPreferences").document(userId).setData(from: preferences)
        print(" Created initial preferences: \(preferences.preferredCategories)")
        
        return preferences
    }
    
    private func getAllEvents() async throws -> [Event] {
        print("🔍 Fetching all events...")

        // Get ALL events from database (remove limit)
        let allSnapshot = try await db.collection("events")
            .order(by: "createdAt", descending: true)
            .getDocuments() // Remove .limit(to: 100)

        let allEvents = allSnapshot.documents.compactMap { doc in
            var event = try? doc.data(as: Event.self)
            event?.id = doc.documentID
            return event
        }

        print("📊 Found \(allEvents.count) total events in database")

        // Now filter for future events manually
        let currentDate = Date()
        let isoFormatter = ISO8601DateFormatter()

        let futureEvents = allEvents.filter { event in
            if let eventDate = isoFormatter.date(from: event.date) {
                let isFuture = eventDate > currentDate
                print("📅 Event: \(event.title) - Date: \(event.date) - Future: \(isFuture)")
                return isFuture
            } else {
                print("⚠️ Could not parse date for event: \(event.title) - Date: \(event.date)")
                return false // Don't include unparseable dates
            }
        }

        print("📅 Found \(futureEvents.count) future events")
        print("📅 Events by category:")
        let eventsByCategory = Dictionary(grouping: futureEvents, by: { $0.category })
        for (category, categoryEvents) in eventsByCategory {
            print("  - \(category): \(categoryEvents.count) events")
        }

        // Debug: Print ALL future events
        print("🔍 All future events:")
        for event in futureEvents {
            print("  - \(event.title) (\(event.category)) - ID: \(event.id ?? "no-id") - Date: \(event.date)")
        }

        return futureEvents
    }
    
    private func filterUserEvents(_ events: [Event], userId: String) async throws -> [Event] {
        // Get user's tickets (attended events)
        let ticketsSnapshot = try await db.collection("tickets")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        let attendedEventIds = Set(ticketsSnapshot.documents.compactMap { doc in
            doc.data()["eventId"] as? String
        })

        // Get user's saved and joined events
        let userDoc = try await db.collection("users").document(userId).getDocument()
        let savedEventIds = Set(userDoc.data()?["savedEventIds"] as? [String] ?? [])
        let joinedEventIds = Set(userDoc.data()?["joinedEventIds"] as? [String] ?? [])

        // Filter out events user has already interacted with
        let filteredEvents = events.filter { event in
            guard let eventId = event.id else { return false }
        
            let hasTicket = attendedEventIds.contains(eventId)
            let hasJoined = joinedEventIds.contains(eventId)
            let hasSaved = savedEventIds.contains(eventId)
        
            return !(hasTicket || hasJoined || hasSaved)
        }

        return filteredEvents
    }
    
    private func scoreEvents(_ events: [Event], preferences: UserPreferences, userId: String) -> [Event] {
        let scoredEvents = events.map { event in
            var scoredEvent = event
            let score = calculateEventScore(event, preferences: preferences, userId: userId)
            scoredEvent.recommendationScore = score
            return scoredEvent
        }
        
        return scoredEvents.sorted { event1, event2 in
            let score1 = event1.recommendationScore ?? 0
            let score2 = event2.recommendationScore ?? 0
            return score1 > score2
        }
    }
    
    private func calculateEventScore(_ event: Event, preferences: UserPreferences, userId: String) -> Double {
        var score: Double = 0
    
        // Category preference score
        if let categoryWeight = preferences.preferredCategories[event.category] {
            score += categoryWeight * 0.4
        } else {
            score -= 0.5
        }
    
        // Location preference score
        if let locationWeight = preferences.preferredLocations[event.location] {
            score += locationWeight * 0.2
        }
    
        // Price preference score
        if let priceRange = preferences.preferredPriceRange {
            if priceRange.contains(event.price) {
                score += 2.0
            } else {
                let distance = min(abs(event.price - priceRange.lowerBound), abs(event.price - priceRange.upperBound))
                score += max(-distance * 0.1, -2.0)
            }
        }
    
        // Time preference score
        let isoFormatter = ISO8601DateFormatter()
        if let eventDate = isoFormatter.date(from: event.date) {
            let hour = Calendar.current.component(.hour, from: eventDate)
            let timeSlot = getTimeSlot(hour: hour)
            if let timeWeight = preferences.preferredTimes[timeSlot] {
                score += timeWeight * 0.2
            }
        }
    
        // Popularity and rating scores
        score += Double(event.attendees) * 0.005
    
        if let rating = event.averageRating {
            score += rating * 0.1
        }
    
        // Urgency score for events happening soon
        if let eventDate = isoFormatter.date(from: event.date) {
            let daysUntilEvent = Calendar.current.dateComponents([.day], from: Date(), to: eventDate).day ?? 0
            if daysUntilEvent <= 7 && daysUntilEvent >= 0 {
                score += 1.0
            }
        }
    
        return max(score, 0)
    }
}