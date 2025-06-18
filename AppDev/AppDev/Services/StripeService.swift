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
    private let backendURL = "http://127.0.0.1:5001"
    
    init() {
        // Use Stripe's test publishable key
        StripeAPI.defaultPublishableKey = "pk_test_51O9yYXFqgJf8BUSdQPXzfCLOF8nw1K6W9WjKejT03KosljCtREbZ8Cgdfo00l0kL3sysjcwGo5HZXPPWCBhxpcI002I4FY6tU"
    }
    
    func preparePaymentSheet(amount: Int, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        // First check if the server is running
        let healthCheckURL = URL(string: "\(backendURL)")!
        var healthCheckRequest = URLRequest(url: healthCheckURL)
        healthCheckRequest.timeoutInterval = 5
        
        URLSession.shared.dataTask(with: healthCheckRequest) { [weak self] _, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false, "Server connection failed: \(error.localizedDescription)")
                }
                return
            }
            
            // If server is running, create payment intent
            let paymentURL = URL(string: "\(self.backendURL)/createPaymentIntent")!
            var request = URLRequest(url: paymentURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10
            
            let body: [String: Any] = ["amount": amount, "currency": "eur"]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.isLoading = false
                        completion(false, "Payment setup failed: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        self.isLoading = false
                        completion(false, "Invalid server response")
                        return
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        self.isLoading = false
                        completion(false, "Server error: \(httpResponse.statusCode)")
                        return
                    }
                    
                    guard let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let clientSecret = json["clientSecret"] as? String else {
                        self.isLoading = false
                        completion(false, "Invalid response format")
                        return
                    }
                    
                    var configuration = PaymentSheet.Configuration()
                    configuration.merchantDisplayName = "AppDev Events"
                    configuration.allowsDelayedPaymentMethods = false
                    
                    self.paymentSheet = PaymentSheet(
                        paymentIntentClientSecret: clientSecret,
                        configuration: configuration
                    )
                    
                    self.isLoading = false
                    completion(true, nil)
                }
            }.resume()
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