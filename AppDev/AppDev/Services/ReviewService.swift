import Foundation
import FirebaseFirestore

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
            "createdAt": Timestamp(date: review.createdAt)
        ]
        
        try await db.collection("reviews").addDocument(data: reviewData)
        
        // Update event's average rating
        try await updateEventRatings(eventId: review.eventId)
    }
    
    func fetchReviews(for eventId: String) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("eventId", isEqualTo: eventId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Review.self)
        }
    }
    
    func checkIfUserReviewed(eventId: String, userId: String) async throws -> Bool {
        let snapshot = try await db.collection("reviews")
            .whereField("eventId", isEqualTo: eventId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    func getEventRatingSummary(eventId: String) async throws -> EventRatingSummary {
        let reviews = try await fetchReviews(for: eventId)
        
        guard !reviews.isEmpty else {
            return EventRatingSummary.empty
        }
        
        let totalReviews = reviews.count
        let avgOverall = reviews.map { $0.overallRating }.reduce(0, +) / Double(totalReviews)
        let avgMusic = reviews.map { $0.musicRating }.reduce(0, +) / Double(totalReviews)
        let avgLocation = reviews.map { $0.locationRating }.reduce(0, +) / Double(totalReviews)
        let avgVibe = reviews.map { $0.vibeRating }.reduce(0, +) / Double(totalReviews)
        
        return EventRatingSummary(
            totalReviews: totalReviews,
            averageOverallRating: avgOverall,
            averageMusicRating: avgMusic,
            averageLocationRating: avgLocation,
            averageVibeRating: avgVibe
        )
    }
    
    private func updateEventRatings(eventId: String) async throws {
        let summary = try await getEventRatingSummary(eventId: eventId)
        
        try await db.collection("events").document(eventId).updateData([
            "averageRating": summary.averageOverallRating,
            "totalReviews": summary.totalReviews
        ])
    }
}