import Foundation
import FirebaseAuth
import Combine

class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = Auth.auth().currentUser != nil

    init() {
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { _, user in
            self.isSignedIn = user != nil
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isSignedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}