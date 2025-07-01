import FirebaseFirestore
import FirebaseAuth
import Foundation

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
        let snapshot = try await db.collection("reviews")
            .whereField("eventId", isEqualTo: eventId)
            .getDocuments()
        
        var reviews = snapshot.documents.compactMap { doc -> Review? in
            var data = doc.data()
            data["id"] = doc.documentID
            
            // Handle Firestore Timestamp conversion
            if let timestamp = data["createdAt"] as? Timestamp {
                data["createdAt"] = timestamp.dateValue()
            }
            
            return try? Review(from: data)
        }
        
        // Sort locally by creation date (descending)
        reviews.sort { $0.createdAt > $1.createdAt }
        
        return reviews
    }
    
    func getEventRatingSummary(eventId: String) async throws -> EventRatingSummary {
        let reviews = try await fetchReviews(for: eventId)
        
        guard !reviews.isEmpty else {
            return EventRatingSummary.empty
        }
        
        let totalOverall = reviews.reduce(0) { $0 + $1.overallRating }
        let totalMusic = reviews.reduce(0) { $0 + $1.musicRating }
        let totalLocation = reviews.reduce(0) { $0 + $1.locationRating }
        let totalVibe = reviews.reduce(0) { $0 + $1.vibeRating }
        
        let count = Double(reviews.count)
        
        return EventRatingSummary(
            averageOverallRating: totalOverall / count,
            averageMusicRating: totalMusic / count,
            averageLocationRating: totalLocation / count,
            averageVibeRating: totalVibe / count,
            totalReviews: reviews.count
        )
    }
    
    private func updateEventAverageRating(eventId: String) async throws {
        let summary = try await getEventRatingSummary(eventId: eventId)
        
        try await db.collection("events").document(eventId).updateData([
            "averageRating": summary.averageOverallRating,
            "totalReviews": summary.totalReviews
        ])
    }
}