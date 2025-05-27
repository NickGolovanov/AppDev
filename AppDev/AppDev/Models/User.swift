import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let email: String
    let fullName: String
    let password: String // Note: This will be stored as hashed password
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName
        case password
    }
} 