import Foundation

struct EventRatingSummary {
    let averageOverallRating: Double
    let averageMusicRating: Double
    let averageLocationRating: Double
    let averageVibeRating: Double
    let totalReviews: Int
    
    static let empty = EventRatingSummary(
        averageOverallRating: 0,
        averageMusicRating: 0,
        averageLocationRating: 0,
        averageVibeRating: 0,
        totalReviews: 0
    )
}