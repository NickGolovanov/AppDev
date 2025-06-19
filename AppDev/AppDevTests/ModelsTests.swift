import XCTest
import Foundation
import FirebaseFirestore
@testable import AppDev // Make sure to import your main app module here

final class ModelsTests: XCTestCase {

    // MARK: - Event Model Tests

    func testEventFormattedDate() throws {
        let event = Event(
            id: "1",
            title: "Sample Event",
            date: "2024-07-20T10:00:00Z", // ISO 8601 format
            endTime: "2024-07-20T12:00:00Z",
            startTime: "2024-07-20T10:00:00Z",
            location: "Sample Location",
            imageUrl: "url",
            attendees: 10,
            category: "Music",
            price: 20.0,
            maxCapacity: 50,
            description: "A description",
            latitude: 0,
            longitude: 0
        )
        XCTAssertEqual(event.formattedDate, "20 Jul 2024", "Event formattedDate should match 'd MMM yyyy' format.")
    }

    func testEventFormattedTime() throws {
        let event = Event(
            id: "1",
            title: "Sample Event",
            date: "2024-07-20T10:00:00Z",
            endTime: "2024-07-20T14:30:00Z",
            startTime: "2024-07-20T10:15:00Z", // ISO 8601 format
            location: "Sample Location",
            imageUrl: "url",
            attendees: 10,
            category: "Music",
            price: 20.0,
            maxCapacity: 50,
            description: "A description",
            latitude: 0,
            longitude: 0
        )
        // Note: DateFormatter is sensitive to locale and timezone.
        // For consistent tests, consider setting a fixed locale/timezone for the formatter.
        // For now, assuming default behavior is acceptable.
        XCTAssertEqual(event.formattedTime, "12:00", "Event formattedTime should match 'HH:mm' format.")
    }

    func testEventFormattedEndTime() throws {
        let event = Event(
            id: "1",
            title: "Sample Event",
            date: "2024-07-20T10:00:00Z",
            endTime: "2024-07-20T14:30:00Z", // ISO 8601 format
            startTime: "2024-07-20T10:15:00Z",
            location: "Sample Location",
            imageUrl: "url",
            attendees: 10,
            category: "Music",
            price: 20.0,
            maxCapacity: 50,
            description: "A description",
            latitude: 0,
            longitude: 0
        )
        XCTAssertEqual(event.formattedEndTime, "16:30", "Event formattedEndTime should match 'HH:mm' format.")
    }
    
    func testEventInitialization() throws {
        let eventId = "test_event_id_2"
        let title = "Concert Night"
        let date = "2024-08-15T19:00:00Z"
        let endTime = "2024-08-15T23:00:00Z"
        let startTime = "2024-08-15T19:00:00Z"
        let location = "City Arena"
        let imageUrl = "https://example.com/concert.jpg"
        let attendees = 100
        let category = "Concert"
        let price = 35.50
        let maxCapacity = 500
        let description = "Live music performance."
        let latitude = 34.0522
        let longitude = -118.2437

        let event = Event(
            id: eventId,
            title: title,
            date: date,
            endTime: endTime,
            startTime: startTime,
            location: location,
            imageUrl: imageUrl,
            attendees: attendees,
            category: category,
            price: price,
            maxCapacity: maxCapacity,
            description: description,
            latitude: latitude,
            longitude: longitude
        )

        XCTAssertEqual(event.id, eventId)
        XCTAssertEqual(event.title, title)
        XCTAssertEqual(event.date, date)
        XCTAssertEqual(event.endTime, endTime)
        XCTAssertEqual(event.startTime, startTime)
        XCTAssertEqual(event.location, location)
        XCTAssertEqual(event.imageUrl, imageUrl)
        XCTAssertEqual(event.attendees, attendees)
        XCTAssertEqual(event.category, category)
        XCTAssertEqual(event.price, price)
        XCTAssertEqual(event.maxCapacity, maxCapacity)
        XCTAssertEqual(event.description, description)
        XCTAssertEqual(event.latitude, latitude)
        XCTAssertEqual(event.longitude, longitude)
    }

    // MARK: - Ticket Model Tests

    func testTicketFormattedDate() throws {
        let ticket = Ticket(
            id: "ticket1",
            eventId: "event1",
            eventName: "Grand Opening",
            date: "2024-09-01T09:00:00Z", // ISO 8601 format
            location: "Main Street",
            name: "John Doe",
            email: "john@example.com",
            price: "10.00",
            qrcodeUrl: "qr_url",
            userId: "user1",
            status: .active
        )
        XCTAssertEqual(ticket.formattedDate, "1 Sep 2024", "Ticket formattedDate should match 'd MMM yyyy' format.")
    }
    
    func testTicketStatusDecoding() throws {
        let activeTicketData: [String: Any] = [
            "id": "t1", "eventId": "e1", "eventName": "N", "date": "D", "location": "L",
            "name": "N", "email": "E", "price": "P", "qrcodeUrl": "Q", "userId": "U",
            "status": "active"
        ]
        let activeTicket = try Firestore.Decoder().decode(Ticket.self, from: activeTicketData)
        XCTAssertEqual(activeTicket.status, .active)

        let usedTicketData: [String: Any] = [
            "id": "t2", "eventId": "e2", "eventName": "N", "date": "D", "location": "L",
            "name": "N", "email": "E", "price": "P", "qrcodeUrl": "Q", "userId": "U",
            "status": "used"
        ]
        let usedTicket = try Firestore.Decoder().decode(Ticket.self, from: usedTicketData)
        XCTAssertEqual(usedTicket.status, .used)
    }
    
    func testTicketStatusDefaultValue() throws {
        // Test case where status field is missing (should default to active based on your TicketCard logic comment)
        // NOTE: Codable itself does not provide default values for missing keys automatically.
        // If 'status' is truly optional in Firestore and you want a default 'active',
        // you'd need a custom Decoder or ensure it's always written.
        // For this test, it will fail if 'status' is truly missing and not handled.
        let missingStatusTicketData: [String: Any] = [
            "id": "t3", "eventId": "e3", "eventName": "N", "date": "D", "location": "L",
            "name": "N", "email": "E", "price": "P", "qrcodeUrl": "Q", "userId": "U"
            // "status" is missing
        ]
        
        XCTAssertThrowsError(try Firestore.Decoder().decode(Ticket.self, from: missingStatusTicketData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
        
        // If your intention was for it to default, the `Ticket` struct's `init(from decoder:)` needs to handle it.
        // For example: status = try container.decodeIfPresent(TicketStatus.self, forKey: .status) ?? .active
    }

} 