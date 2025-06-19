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
                guard let user = res?.user else { return }
                print(user)
                
                //----Added code for user document testing----
                let db = Firestore.firestore()
                let userRef = db.collection( "users" ).document( user.uid )
                userRef.getDocument { document, error in
                    if let document = document, document.exists {
                        // User document already exists, do nothin
                    } else {
                        let userData: [String: Any] = [
                            "email": user.email ?? "",
                            "fullname": user.displayName ?? "",
                            "username": "@" + (user.displayName ?? "").lowercased().replacingOccurrences(of: " ", with: ""),
                            "description": "",
                            "profileImageUrl": user.photoURL?.absoluteString ?? ""
                        ]
                        userRef.setData(userData) { error in
                            if let error = error {
                                print ("Error creating user document: \(error.localizedDescription)")
                            } else {
                                print ("User document created for Google user")
                            }
                        }
                    }
                }
                //---------------------
            }
        }
        
    }
    
    func logout() async throws{
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }
   
}
