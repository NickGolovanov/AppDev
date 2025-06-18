import Foundation
import Stripe
import FirebaseFirestore
import StripePaymentSheet
import UIKit

class StripeService: ObservableObject {
    private let db = Firestore.firestore()
    
    init() {
        // Use Stripe's test publishable key
        StripeAPI.defaultPublishableKey = "pk_test_51O9yYXFqgJf8BUSdQPXzfCLOF8nw1K6W9WjKejT03KosljCtREbZ8Cgdfo00l0kL3sysjcwGo5HZXPPWCBhxpcI002I4FY6tU"
    }
    
    func validateCard(completion: @escaping (Bool) -> Void) {
        // Create a basic PaymentIntent for validation
        let backendURL = URL(string: "http://localhost:5001/createPaymentIntent")!
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Minimal amount for validation (1 euro in cents)
        let body: [String: Any] = ["amount": 100, "currency": "eur"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let clientSecret = json["clientSecret"] as? String {
                    DispatchQueue.main.async {
                        // Show card input form
                        var configuration = PaymentSheet.Configuration()
                        configuration.merchantDisplayName = "AppDev Events"
                        configuration.allowsDelayedPaymentMethods = false
                        
                        let paymentSheet = PaymentSheet(
                            paymentIntentClientSecret: clientSecret,
                            configuration: configuration
                        )
                        
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
                } else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }.resume()
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