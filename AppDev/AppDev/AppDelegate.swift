import UIKit
import FirebaseAppCheck
import FirebaseCore
import FirebaseFirestore
import FirebaseAnalytics

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Disable App Check for development
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        // Test Firebase Analytics
        Analytics.logEvent("app_launched", parameters: [
            "test_parameter": "Firebase is working!"
        ])
        
        return true
    }
} 
