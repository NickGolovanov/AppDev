//
//  EditProfileView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

import Foundation
import FirebaseFirestore

import SwiftUI

struct EditProfileView: View {
    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var userId: String = ""
    @State private var email: String = ""
    @State private var profileImageUrl: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Profile Image Placeholder
                Button(action: {
                    // Will open image picker later
                }) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }

                // Full Name Field
                VStack(alignment: .leading) {
                    Text("Full Name")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Enter your full name", text: $fullName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // Username Field
                VStack(alignment: .leading) {
                    Text("Username")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("@username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // Bio Field
                VStack(alignment: .leading) {
                    Text("Bio")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextEditor(text: $bio)
                        .frame(height: 100)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                }

                // User ID Field
                VStack(alignment: .leading) {
                    Text("User ID")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Enter user ID", text: $userId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // Email Field
                VStack(alignment: .leading) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // Profile Image URL Field
                VStack(alignment: .leading) {
                    Text("Profile Image URL")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Enter profile image URL", text: $profileImageUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // Save Button
                Button(action: {
                    let db = Firestore.firestore()
                    let userData: [String: Any] = [
                        "fullName": fullName,
                        "username": username,
                        "description": bio,
                        "email": email,
                        "profileImageUrl": profileImageUrl,
                        "joinedEventIds": [],
                        "organizedEventIds": []
                    ]
                    db.collection("users").document(userId).setData(userData) { error in
                        if let error = error {
                            print("Error writing user data: \(error)")
                        } else {
                            print("User data successfully written!")
                        }
                    }
                }) {
                    Text("Save Profile")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 30)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Profile Update"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
            .padding()
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    EditProfileView()
}
