//
//  AuthenticationView.swift
//  AppDev
//
//  Created by Informatica Emmen on 13/06/2025.
//


import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseCore
import GoogleSignInSwift
import FirebaseAuth
import FirebaseFirestore


class AuthenticationView: ObservableObject{
    
    @Published var isLoginSuccessed = false
    
    
    func signInWithGoogle(){
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: Application_utility.rootViewController) { user, error in
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard
                let user = user?.user,
                let idToken = user.idToken else { return }
            
            let accessToken = user.accessToken
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { res, error in
                if let error = error{
                    print(error.localizedDescription)
                    return
                }
                guard let firebaseUser = res?.user else { return }
                print("Google Auth successful for user: \(firebaseUser.uid)")
                
                // Check if user already exists in Firestore
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(firebaseUser.uid)
                
                userRef.getDocument { document, error in
                    if let document = document, document.exists {
                        print("User already exists in Firestore")
                        return
                    } else {
                        // User doesn't exist in Firestore, create new user document
                        print("Creating new user document in Firestore")
                        
                        let displayName = firebaseUser.displayName ?? ""
                        let email = firebaseUser.email ?? ""
                        
                        // Generate username from display name or email
                        let username = self.generateUsername(from: displayName, email: email)
                        
                        let userData = User(
                            email: email,
                            fullName: displayName,
                            username: username,
                            description: "",
                            profileImageURL: firebaseUser.photoURL?.absoluteString ?? "",
                            password: "" // Google Auth users don't have passwords stored locally
                        )
                        
                        do {
                            try userRef.setData(from: userData)
                            print("Google Auth user successfully saved to Firestore")
                        } catch {
                            print("Failed to save Google Auth user to Firestore: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        
    }
    
    private func generateUsername(from displayName: String, email: String) -> String {
        if !displayName.isEmpty {
            // Generate username from display name
            return "@" + displayName.lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
        } else {
            // Fallback to email prefix
            let emailPrefix = String(email.split(separator: "@").first ?? "user")
            return "@" + emailPrefix.lowercased()
                .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
        }
    }
    
    func logout() async throws{
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }
   
}
