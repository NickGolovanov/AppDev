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
            try db.collection("userBehavior").addDocument(from: behavior)
            
            // Update user preferences based on this action
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
            } else {
                preferences = UserPreferences(userId: userId)
            }
            
            // Update preferences based on behavior
            updatePreferencesWithBehavior(&preferences, behavior: behavior)
            
            try preferencesRef.setData(from: preferences)
        } catch {
            print("Error updating user preferences: \(error)")
        }
    }
    
    private func updatePreferencesWithBehavior(_ preferences: inout UserPreferences, behavior: UserBehavior) {
        let weight = getActionWeight(behavior.actionType)
        
        // Update category preferences
        if let category = behavior.eventCategory {
            preferences.preferredCategories[category, default: 0] += weight
        }
        
        // Update location preferences
        if let location = behavior.eventLocation {
            preferences.preferredLocations[location, default: 0] += weight
        }
        
        // Update time preferences (simplified - using hour of day)
        let hour = Calendar.current.component(.hour, from: behavior.timestamp)
        let timeSlot = getTimeSlot(hour: hour)
        preferences.preferredTimes[timeSlot, default: 0] += weight
        
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
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Get user preferences
            let preferences = try await getUserPreferences(userId: userId)
            
            // Get all available events
            let allEvents = try await getAllEvents()
            
            // Score and rank events
            let scoredEvents = scoreEvents(allEvents, preferences: preferences, userId: userId)
            
            // Get top recommendations
            let recommendations = Array(scoredEvents.prefix(10))
            
            DispatchQueue.main.async {
                self.recommendedEvents = recommendations
                self.isLoading = false
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to generate recommendations: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func getUserPreferences(userId: String) async throws -> UserPreferences {
        let document = try await db.collection("userPreferences").document(userId).getDocument()
        
        if document.exists {
            return try document.data(as: UserPreferences.self)
        } else {
            // Create default preferences based on user behavior
            return try await createDefaultPreferences(userId: userId)
        }
    }
    
    private func createDefaultPreferences(userId: String) async throws -> UserPreferences {
        // Analyze user's past behavior to create initial preferences
        let behaviorQuery = db.collection("userBehavior")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
        
        let behaviorSnapshot = try await behaviorQuery.getDocuments()
        let behaviors = behaviorSnapshot.documents.compactMap { try? $0.data(as: UserBehavior.self) }
        
        var preferences = UserPreferences(userId: userId)
        
        // Analyze behaviors to set initial preferences
        for behavior in behaviors {
            updatePreferencesWithBehavior(&preferences, behavior: behavior)
        }
        
        // Save preferences
        try db.collection("userPreferences").document(userId).setData(from: preferences)
        
        return preferences
    }
    
    private func getAllEvents() async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("date", isGreaterThan: Date())
            .order(by: "date")
            .limit(to: 100)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            var event = try? doc.data(as: Event.self)
            event?.id = doc.documentID
            return event
        }
    }
    
    private func scoreEvents(_ events: [Event], preferences: UserPreferences, userId: String) -> [Event] {
        return events.map { event in
            var scoredEvent = event
            let score = calculateEventScore(event, preferences: preferences, userId: userId)
            // I add the score as a computed property or separate dictionary
            return scoredEvent
        }.sorted { event1, event2 in
            let score1 = calculateEventScore(event1, preferences: preferences, userId: userId)
            let score2 = calculateEventScore(event2, preferences: preferences, userId: userId)
            return score1 > score2
        }
    }
    
    private func calculateEventScore(_ event: Event, preferences: UserPreferences, userId: String) -> Double {
        var score: Double = 0
        
        // Category preference score
        if let categoryWeight = preferences.preferredCategories[event.category] {
            score += categoryWeight * 0.3
        }
        
        if let locationWeight = preferences.preferredLocations[event.location] {
            score += locationWeight * 0.2
        }
        
        if let priceRange = preferences.preferredPriceRange {
            if priceRange.contains(event.price) {
                score += 2.0
            } else {
                let distance = min(abs(event.price - priceRange.lowerBound), abs(event.price - priceRange.upperBound))
                score -= distance * 0.1
            }
        }
        
        let isoFormatter = ISO8601DateFormatter()
        if let eventDate = isoFormatter.date(from: event.date) {
            let hour = Calendar.current.component(.hour, from: eventDate)
            let timeSlot = getTimeSlot(hour: hour)
            if let timeWeight = preferences.preferredTimes[timeSlot] {
                score += timeWeight * 0.2
            }
        }
        
        score += Double(event.attendees) * 0.01
        if let rating = event.averageRating {
            score += rating * 0.3
        }
        
        if let eventDate = isoFormatter.date(from: event.date) {
            let daysUntilEvent = Calendar.current.dateComponents([.day], from: Date(), to: eventDate).day ?? 0
            if daysUntilEvent <= 7 {
                score += 1.0
            }
        }
        
        return max(score, 0)
    }
}