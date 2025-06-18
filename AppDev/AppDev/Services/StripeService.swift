import Foundation
import Stripe
import FirebaseFirestore
import StripePaymentSheet
import UIKit

class StripeService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var paymentSheet: PaymentSheet?
    @Published var isLoading = false
    
    init() {
        // Use Stripe's test publishable key
        StripeAPI.defaultPublishableKey = "pk_test_51O9yYXFqgJf8BUSdQPXzfCLOF8nw1K6W9WjKejT03KosljCtREbZ8Cgdfo00l0kL3sysjcwGo5HZXPPWCBhxpcI002I4FY6tU"
    }
    
    func preparePaymentSheet(amount: Int, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        // Create a PaymentIntent on the backend
        let backendURL = URL(string: "http://localhost:5001/createPaymentIntent")!
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["amount": amount, "currency": "eur"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let clientSecret = json["clientSecret"] as? String else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    completion(false)
                }
                return
            }
            
            DispatchQueue.main.async {
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "AppDev Events"
                configuration.allowsDelayedPaymentMethods = false
                
                self.paymentSheet = PaymentSheet(
                    paymentIntentClientSecret: clientSecret,
                    configuration: configuration
                )
                
                self.isLoading = false
                completion(true)
            }
        }.resume()
    }
    
    func presentPaymentSheet(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let paymentSheet = paymentSheet else {
            completion(false)
            return
        }
        
        paymentSheet.present(from: viewController) { result in
            switch result {
            case .completed:
                completion(true)
            case .failed(let error):
                print("Payment failed: \(error.localizedDescription)")
                completion(false)
            case .canceled:
                print("Payment canceled")
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