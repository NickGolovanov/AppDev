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
        // Show card input form
        let config = PaymentSheet.Configuration()
        let paymentSheet = PaymentSheet(configuration: config)
        
        // Present the payment sheet
        paymentSheet.present(from: UIApplication.shared.windows.first?.rootViewController ?? UIViewController()) { result in
            switch result {
            case .completed:
                completion(true)
            case .failed, .canceled:
                completion(false)
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