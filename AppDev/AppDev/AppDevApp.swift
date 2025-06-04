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

@main
struct AppDevApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("userId") var userId: String = ""

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
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
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isAuthenticated = user != nil
                if let firebaseUser = user {
                    self.appStorageUserId = firebaseUser.uid
                    self.fetchUserProfile(email: firebaseUser.email)
                } else {
                    self.appStorageUserId = ""
                    self.currentUser = nil
                }
            }
        }
    }

    private func fetchUserProfile(email: String?) {
        guard let email = email else { return }
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: email).getDocuments {
            snapshot, error in
            if let doc = snapshot?.documents.first, let user = try? doc.data(as: User.self) {
                DispatchQueue.main.async {
                    self.currentUser = user
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.appStorageUserId = ""
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
