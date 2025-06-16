//
//  EditProfileView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

import Firebase
import FirebaseFirestore
import FirebaseStorage
import Foundation
import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var email: String = ""
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    @State private var showSuccessAlert = false
    @AppStorage("userId") var userId: String = ""
    @State private var profileImageUrl: String = ""
    @State private var profileUpdatedAndReadyToDismiss: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Image Picker
                Button(action: {
                    showImagePicker = true
                }) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(Color(hex: "#7131C5"))
                    }
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $profileImage)
                }

                labeledTextField("Full Name", text: $fullName)
                labeledTextField("Username", text: $username, prefix: "@")
                labeledTextEditor("Description", text: $bio)
                labeledTextField("Email", text: $email, keyboardType: .emailAddress)

                // Save Button
                Button(action: saveProfile) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#7131C5"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 30)
            }
            .padding()
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("Ok") {
                if profileUpdatedAndReadyToDismiss {
                    print("EditProfileView: Dismissing view via dismiss() after OK.")
                    dismiss()
                }
            }
        } message: {
            Text("Profile updated successfully!")
        }
        .onAppear(perform: fetchUserData)
    }

    func saveProfile() {
        guard !userId.isEmpty else { return }
        guard !fullName.isEmpty, !username.isEmpty, !email.isEmpty else { return }

        let userDataToUpdate: [String: Any] = [
            "fullName": fullName,
            "username": username,
            "description": bio,
            "email": email,
            "profileImageUrl": profileImageUrl
        ]

        Firestore.firestore().collection("users").document(userId).updateData(userDataToUpdate) { error in
            if error == nil {
                profileUpdatedAndReadyToDismiss = true
                print("EditProfileView: Profile saved successfully. Showing success alert.")
                showSuccessAlert = true
            } else {
                print("EditProfileView: Error saving profile: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }

    func fetchUserData() {
        guard !userId.isEmpty else { return }

        Firestore.firestore().collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                fullName = data?["fullName"] as? String ?? ""
                username = data?["username"] as? String ?? ""
                bio = data?["description"] as? String ?? ""
                email = data?["email"] as? String ?? ""
                profileImageUrl = data?["profileImageUrl"] as? String ?? ""
            }
        }
    }

    func labeledTextField(
        _ label: String, text: Binding<String>, prefix: String = "",
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            TextField(prefix, text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
        }
    }

    func labeledTextEditor(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            TextEditor(text: text)
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
        }
    }
}

#Preview {
    EditProfileView()
}
