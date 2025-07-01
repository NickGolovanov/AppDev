import FirebaseFirestore
import FirebaseAuth

class ReviewService: ObservableObject {
    private let db = Firestore.firestore()
    
    func submitReview(_ review: Review) async throws {
        let reviewData: [String: Any] = [
            "eventId": review.eventId,
            "userId": review.userId,
            "userName": review.userName,
            "userProfileImageUrl": review.userProfileImageUrl ?? "",
            "overallRating": review.overallRating,
            "musicRating": review.musicRating,
            "locationRating": review.locationRating,
            "vibeRating": review.vibeRating,
            "comment": review.comment,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("reviews").addDocument(data: reviewData)
        
        // Update event's average rating
        try await updateEventAverageRating(eventId: review.eventId)
    }
    
    func checkIfUserReviewed(eventId: String, userId: String) async throws -> Bool {
        let query = db.collection("reviews")
            .whereField("eventId", isEqualTo: eventId)
            .whereField("userId", isEqualTo: userId)
        
        let snapshot = try await query.getDocuments()
        return !snapshot.isEmpty
    }
    
    func fetchReviews(for eventId: String) async throws -> [Review] {
        // Simple query without ordering to avoid index requirement
        let snapshot = try await db.collection("reviews")
            .whereField("eventId", isEqualTo: eventId)
            .getDocuments()
        
        var reviews = snapshot.documents.compactMap { doc in
            try? doc.data(as: Review.self)
        }
        
        // Sort locally by creation date (descending)
        reviews.sort { $0.createdAt > $1.createdAt }
        
        return reviews
    }
    
    private func updateEventAverageRating(eventId: String) async throws {
        let reviews = try await fetchReviews(for: eventId)
        
        guard !reviews.isEmpty else { return }
        
        let totalRating = reviews.reduce(0) { $0 + $1.overallRating }
        let averageRating = totalRating / Double(reviews.count)
        
        try await db.collection("events").document(eventId).updateData([
            "averageRating": averageRating,
            "totalReviews": reviews.count
        ])
    }
}