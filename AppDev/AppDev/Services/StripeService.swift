import Foundation
import Stripe
import FirebaseFirestore

class StripeService: ObservableObject {
    private let db = Firestore.firestore()
    
    init() {
        StripeAPI.defaultPublishableKey = StripeConfig.publishableKey
    }
    
    func createPaymentIntent(amount: Int, currency: String, eventId: String, userId: String) async throws -> String {
        // IMPORTANT: This needs to call your backend to create a Payment Intent.
        // The Stripe secret key should NEVER be exposed in the app.
        
        // TODO: Replace with your backend URL. We will set this up next.
        guard let url = URL(string: "http://127.0.0.1:5001/appdev-929a6/us-central1/createPaymentIntent") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "amount": amount,
            "currency": currency,
            "eventId": eventId,
            "userId": userId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            print("StripeService: Bad response from server. Status: \((response as? HTTPURLResponse)?.statusCode ?? 0). Body: \(responseBody)")
            throw URLError(.badServerResponse)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let clientSecret = json["clientSecret"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        
        return clientSecret
    }
    
    func handleSuccessfulPayment(eventId: String, userId: String) async throws {
        // Update event attendees count
        let eventRef = db.collection("events").document(eventId)
        try await eventRef.updateData([
            "attendees": FieldValue.increment(Int64(1))
        ])
        
        // Update user's joined events
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "joinedEventIds": FieldValue.arrayUnion([eventId])
        ])
    }
} 