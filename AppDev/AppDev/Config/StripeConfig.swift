import Foundation

enum StripeConfig {
    static let publishableKey: String = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let key = dict["STRIPE_PUBLISHABLE_KEY"] as? String else {
            fatalError("Stripe publishable key not found in Config.plist")
        }
        return key
    }()
} 