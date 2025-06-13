//
//  AppDevApp.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import SwiftUI
import GoogleSignIn
import Firebase

@main
struct AppDevApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("userId") var userId: String = ""

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                InitialView()
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User? = nil
    @AppStorage("userId") var appStorageUserId: String = ""

    init() {
        print("\n--- AuthViewModel: Initializing ---")
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isAuthenticated = user != nil
                if let firebaseUser = user {
                    print("AuthViewModel: Firebase user detected: \(firebaseUser.uid), email: \(firebaseUser.email ?? "nil")")
                    self.appStorageUserId = firebaseUser.uid
                    self.fetchUserProfile(email: firebaseUser.email)
                } else {
                    print("AuthViewModel: No Firebase user detected (signed out or not logged in).")
                    self.appStorageUserId = ""
                    self.currentUser = nil
                }
            }
        }
    }

    private func fetchUserProfile(email: String?) {
        guard let email = email else {
            print("AuthViewModel: fetchUserProfile - email is nil, returning.")
            return
        }
        print("AuthViewModel: Attempting to fetch user profile for email: \(email)")
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: email).getDocuments {
            snapshot, error in
            if let error = error {
                print("AuthViewModel: Error fetching user profile from Firestore: \(error.localizedDescription)")
                return
            }
            if let doc = snapshot?.documents.first, let user = try? doc.data(as: User.self) {
                DispatchQueue.main.async {
                    self.currentUser = user
                    print("AuthViewModel: Successfully set currentUser: \(user.fullName) (ID: \(user.id ?? "nil"))")
                }
            } else {
                print("AuthViewModel: No user document found for email \(email) or decoding failed.")
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.appStorageUserId = ""
            print("AuthViewModel: User signed out successfully.")
        } catch {
            print("AuthViewModel: Error signing out: \(error.localizedDescription)")
        }
    }
}
