import Foundation
import FirebaseFirestore

struct Review: Identifiable, Codable {
    @DocumentID var id: String?
    let eventId: String
    let userId: String
    let userName: String
    let userProfileImageUrl: String?
    let overallRating: Double
    let musicRating: Double
    let locationRating: Double
    let vibeRating: Double
    let comment: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, eventId, userId, userName, userProfileImageUrl
        case overallRating, musicRating, locationRating, vibeRating
        case comment, createdAt
    }
}

struct EventRatingSummary {
    let totalReviews: Int
    let averageOverallRating: Double
    let averageMusicRating: Double
    let averageLocationRating: Double
    let averageVibeRating: Double
    
    static let empty = EventRatingSummary(
        totalReviews: 0,
        averageOverallRating: 0.0,
        averageMusicRating: 0.0,
        averageLocationRating: 0.0,
        averageVibeRating: 0.0
    )
}