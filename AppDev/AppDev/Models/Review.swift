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
    
    init(id: String? = nil,
         eventId: String,
         userId: String,
         userName: String,
         userProfileImageUrl: String?,
         overallRating: Double,
         musicRating: Double,
         locationRating: Double,
         vibeRating: Double,
         comment: String,
         createdAt: Date) {
        self.id = id
        self.eventId = eventId
        self.userId = userId
        self.userName = userName
        self.userProfileImageUrl = userProfileImageUrl
        self.overallRating = overallRating
        self.musicRating = musicRating
        self.locationRating = locationRating
        self.vibeRating = vibeRating
        self.comment = comment
        self.createdAt = createdAt
    }
    
    init(from data: [String: Any]) throws {
        guard let eventId = data["eventId"] as? String,
              let userId = data["userId"] as? String,
              let userName = data["userName"] as? String,
              let overallRating = data["overallRating"] as? Double,
              let musicRating = data["musicRating"] as? Double,
              let locationRating = data["locationRating"] as? Double,
              let vibeRating = data["vibeRating"] as? Double,
              let comment = data["comment"] as? String,
              let createdAt = data["createdAt"] as? Date else {
            throw NSError(domain: "ReviewDecoding", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode review"])
        }
        
        self.id = data["id"] as? String
        self.eventId = eventId
        self.userId = userId
        self.userName = userName
        self.userProfileImageUrl = data["userProfileImageUrl"] as? String
        self.overallRating = overallRating
        self.musicRating = musicRating
        self.locationRating = locationRating
        self.vibeRating = vibeRating
        self.comment = comment
        self.createdAt = createdAt
    }
}