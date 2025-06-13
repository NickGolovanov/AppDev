import Foundation
import Stripe
import FirebaseFirestore

class StripeService: ObservableObject {
    private let stripe = Stripe.shared
    private let db = Firestore.firestore()
    
    init() {
        StripeAPI.defaultPublishableKey = StripeConfig.publishableKey
    }
    
    func createPaymentIntent(amount: Int, currency: String, eventId: String, userId: String) async throws -> String {
        // Create a payment intent using Stripe's API
        let paymentIntentParams = STPPaymentIntentParams()
        paymentIntentParams.amount = NSNumber(value: amount)
        paymentIntentParams.currency = currency
        paymentIntentParams.paymentMethodTypes = ["card"]
        
        // Add metadata
        paymentIntentParams.metadata = [
            "eventId": eventId,
            "userId": userId
        ]
        
        // Create the payment intent
        let paymentIntent = try await STPPaymentIntent.create(paymentIntentParams: paymentIntentParams)
        return paymentIntent.clientSecret
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