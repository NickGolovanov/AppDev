import FirebaseFirestore
import FirebaseAuth
import Foundation

class TestDataService {
    private let db = Firestore.firestore()
    
    // Create sample events for testing
    func createTestEvents() async {
        let testEvents = [
            Event(
                title: "Electronic Music Festival",
                date: "2025-07-10T20:00:00Z",
                endTime: "2025-07-11T02:00:00Z",
                startTime: "2025-07-10T20:00:00Z",
                location: "Amsterdam Central",
                imageUrl: "https://example.com/electronic.jpg",
                attendees: 150,
                category: "Electronic",
                price: 25.0,
                maxCapacity: 200,
                description: "Amazing electronic music festival with top DJs",
                latitude: 52.3792,
                longitude: 4.9003,
                averageRating: 4.5,
                totalReviews: 45
            ),
            Event(
                title: "Jazz Night at Blue Note",
                date: "2025-07-08T19:00:00Z",
                endTime: "2025-07-08T23:00:00Z",
                startTime: "2025-07-08T19:00:00Z",
                location: "Blue Note Amsterdam",
                imageUrl: "https://example.com/jazz.jpg",
                attendees: 80,
                category: "Jazz",
                price: 15.0,
                maxCapacity: 120,
                description: "Intimate jazz evening with live performances",
                latitude: 52.3676,
                longitude: 4.9041,
                averageRating: 4.2,
                totalReviews: 23
            ),
            Event(
                title: "House Party Rooftop",
                date: "2025-07-12T18:00:00Z",
                endTime: "2025-07-13T01:00:00Z",
                startTime: "2025-07-12T18:00:00Z",
                location: "Rooftop Amsterdam",
                imageUrl: "https://example.com/house.jpg",
                attendees: 95,
                category: "House",
                price: 20.0,
                maxCapacity: 150,
                description: "House music party with city views",
                latitude: 52.3702,
                longitude: 4.8952,
                averageRating: 4.7,
                totalReviews: 67
            ),
            Event(
                title: "Rock Concert Live",
                date: "2025-07-15T21:00:00Z",
                endTime: "2025-07-16T00:00:00Z",
                startTime: "2025-07-15T21:00:00Z",
                location: "Melkweg Amsterdam",
                imageUrl: "https://example.com/rock.jpg",
                attendees: 200,
                category: "Rock",
                price: 30.0,
                maxCapacity: 300,
                description: "High-energy rock concert",
                latitude: 52.3639,
                longitude: 4.8838,
                averageRating: 4.1,
                totalReviews: 89
            ),
            Event(
                title: "Techno Underground",
                date: "2025-07-20T22:00:00Z",
                endTime: "2025-07-21T06:00:00Z",
                startTime: "2025-07-20T22:00:00Z",
                location: "Warehouse District",
                imageUrl: "https://example.com/techno.jpg",
                attendees: 120,
                category: "Electronic",
                price: 35.0,
                maxCapacity: 180,
                description: "Underground techno rave experience",
                latitude: 52.3547,
                longitude: 4.9167,
                averageRating: 4.8,
                totalReviews: 156
            )
        ]
        
        for event in testEvents {
            do {
                try db.collection("events").addDocument(from: event)
                print("✅ Created test event: \(event.title)")
            } catch {
                print("❌ Failed to create event \(event.title): \(error)")
            }
        }
    }
    
    // Simulate user behavior for testing recommendations
    func simulateUserBehavior(userId: String) async {
        let behaviors = [
            // User likes Electronic music
            UserBehavior(userId: userId, eventId: "electronic-1", actionType: .clicked, timestamp: Date().addingTimeInterval(-86400 * 7), eventCategory: "Electronic", eventPrice: 25.0, eventLocation: "Amsterdam Central"),
            UserBehavior(userId: userId, eventId: "electronic-1", actionType: .attended, timestamp: Date().addingTimeInterval(-86400 * 6), eventCategory: "Electronic", eventPrice: 25.0, eventLocation: "Amsterdam Central"),
            UserBehavior(userId: userId, eventId: "electronic-1", actionType: .rated, timestamp: Date().addingTimeInterval(-86400 * 5), eventCategory: "Electronic", eventPrice: 25.0, eventLocation: "Amsterdam Central"),
            
            // User also likes House music
            UserBehavior(userId: userId, eventId: "house-1", actionType: .clicked, timestamp: Date().addingTimeInterval(-86400 * 4), eventCategory: "House", eventPrice: 20.0, eventLocation: "Rooftop Amsterdam"),
            UserBehavior(userId: userId, eventId: "house-1", actionType: .saved, timestamp: Date().addingTimeInterval(-86400 * 3), eventCategory: "House", eventPrice: 20.0, eventLocation: "Rooftop Amsterdam"),
            
            // User clicked on Jazz but didn't attend (lower preference)
            UserBehavior(userId: userId, eventId: "jazz-1", actionType: .clicked, timestamp: Date().addingTimeInterval(-86400 * 2), eventCategory: "Jazz", eventPrice: 15.0, eventLocation: "Blue Note Amsterdam"),
            
            // User prefers evening events
            UserBehavior(userId: userId, eventId: "evening-event", actionType: .clicked, timestamp: Date().addingTimeInterval(-86400 * 1), eventCategory: "Electronic", eventPrice: 30.0, eventLocation: "Amsterdam Central")
        ]
        
        for behavior in behaviors {
            do {
                try db.collection("userBehavior").addDocument(from: behavior)
                print("✅ Created behavior: \(behavior.actionType) for \(behavior.eventCategory ?? "unknown")")
            } catch {
                print("❌ Failed to create behavior: \(error)")
            }
        }
    }
}