import Foundation
import Stripe
import StripePaymentSheet

class PaymentViewModel: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func preparePaymentSheet(amount: Int, currency: String = "usd") {
        isLoading = true
        errorMessage = nil
        
        // Create a payment intent on your backend
        let url = URL(string: "your_backend_url/create-payment-intent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "amount": amount,
            "currency": currency
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let clientSecret = json["clientSecret"] as? String else {
                    self?.errorMessage = "Failed to create payment intent"
                    return
                }
                
                // Create the PaymentSheet
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Your App Name"
                configuration.allowsDelayedPaymentMethods = true
                
                self?.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
            }
        }.resume()
    }
    
    func onPaymentCompletion(result: PaymentSheetResult) {
        self.paymentResult = result
        
        switch result {
        case .completed:
            print("Payment completed!")
        case .failed(let error):
            print("Payment failed: \(error.localizedDescription)")
        case .canceled:
            print("Payment canceled!")
        }
    }
} 