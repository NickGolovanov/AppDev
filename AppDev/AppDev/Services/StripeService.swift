import Foundation
import Stripe
import FirebaseFirestore
import StripePaymentSheet
import UIKit

class StripeService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var paymentSheet: PaymentSheet?
    @Published var isLoading = false
    
    // Use your computer's IP address here if testing on a real device
    private let backendURL = "http://10.110.110.179:5001"
    
    init() {
        // Use Stripe's test publishable key
        StripeAPI.defaultPublishableKey = "pk_test_51O9yYXFqgJf8BUSdQPXzfCLOF8nw1K6W9WjKejT03KosljCtREbZ8Cgdfo00l0kL3sysjcwGo5HZXPPWCBhxpcI002I4FY6tU"
    }
    
    func preparePaymentSheet(amount: Int, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        // Create payment intent
        let paymentURL = URL(string: "\(backendURL)/createPaymentIntent")!
        var request = URLRequest(url: paymentURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["amount": amount, "currency": "eur"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let clientSecret = json["clientSecret"] as? String else {
                    self.isLoading = false
                    completion(false, "Invalid response from server")
                    return
                }
                
                // Configure payment sheet
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "AppDev Events"
                configuration.allowsDelayedPaymentMethods = false
                configuration.defaultBillingDetails.address.country = "NL" // Set to Netherlands
                
                // Create payment sheet
                self.paymentSheet = PaymentSheet(
                    paymentIntentClientSecret: clientSecret,
                    configuration: configuration
                )
                
                self.isLoading = false
                completion(true, nil)
            }
        }.resume()
    }
    
    func presentPaymentSheet(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let paymentSheet = paymentSheet else {
            print("Payment sheet not initialized")
            completion(false)
            return
        }
        
        paymentSheet.present(from: viewController) { result in
            switch result {
            case .completed:
                print("Payment completed")
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