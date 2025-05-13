import UIKit
import FirebaseCore
import FirebaseAnalytics

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Test Firebase Analytics
        Analytics.logEvent("app_launched", parameters: [
            "test_parameter": "Firebase is working!"
        ])
        
        return true
    }
} 