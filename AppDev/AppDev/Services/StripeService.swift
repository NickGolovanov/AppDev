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
        // Initialize Stripe SDK with your publishable key
        STPAPIClient.shared.publishableKey = "pk_test_51O9yYXFqgJf8BUSdQPXzfCLOF8nw1K6W9WjKejT03KosljCtREbZ8Cgdfo00l0kL3sysjcwGo5HZXPPWCBhxpcI002I4FY6tU"
    }
    
    func preparePaymentSheet(amount: Int, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        print("Preparing payment sheet for amount: \(amount)")
        
        // Create payment intent request
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
                    print("Network error: \(error.localizedDescription)")
                    self.isLoading = false
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received from server")
                    self.isLoading = false
                    completion(false, "No data received from server")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let clientSecret = json["clientSecret"] as? String {
                        print("Received client secret: \(clientSecret)")
                        
                        // Configure the payment sheet
                        var configuration = PaymentSheet.Configuration()
                        configuration.merchantDisplayName = "AppDev Events"
                        configuration.allowsDelayedPaymentMethods = false
                        configuration.defaultBillingDetails.address.country = "NL"
                        
                        // Create the payment sheet
                        let paymentSheet = PaymentSheet(
                            paymentIntentClientSecret: clientSecret,
                            configuration: configuration
                        )
                        
                        self.paymentSheet = paymentSheet
                        self.isLoading = false
                        print("Payment sheet created successfully")
                        completion(true, nil)
                    } else {
                        print("Invalid response format")
                        self.isLoading = false
                        completion(false, "Invalid response from server")
                    }
                } catch {
                    print("JSON parsing error: \(error.localizedDescription)")
                    self.isLoading = false
                    completion(false, "Could not process server response")
                }
            }
        }.resume()
    }
    
    func presentPaymentSheet(from viewController: UIViewController) async -> Bool {
        guard let paymentSheet = paymentSheet else {
            print("Payment sheet not initialized")
            return false
        }
        
        return await withCheckedContinuation { continuation in
            paymentSheet.present(from: viewController) { result in
                switch result {
                case .completed:
                    print("Payment completed successfully")
                    continuation.resume(returning: true)
                case .failed(let error):
                    print("Payment failed: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                case .canceled:
                    print("Payment canceled by user")
                    continuation.resume(returning: false)
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