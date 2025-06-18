import Foundation
import Stripe
import FirebaseFirestore

class StripeService: ObservableObject {
    private let db = Firestore.firestore()
    
    init() {
        // Use Stripe's test publishable key
        StripeAPI.defaultPublishableKey = "pk_test_51O9yYXFqgJf8BUSdQPXzfCLOF8nw1K6W9WjKejT03KosljCtREbZ8Cgdfo00l0kL3sysjcwGo5HZXPPWCBhxpcI002I4FY6tU"
    }
    
    func validateCard(completion: @escaping (Bool) -> Void) {
        // Create a PaymentMethod without charging
        let card = STPPaymentMethodCardParams()
        let billingDetails = STPPaymentMethodBillingDetails()
        let params = STPPaymentMethodParams(card: card, billingDetails: billingDetails, metadata: nil)
        
        STPAPIClient.shared.createPaymentMethod(with: params) { paymentMethod, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Card validation failed: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Card validation successful")
                    completion(true)
                }
            }
        }
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