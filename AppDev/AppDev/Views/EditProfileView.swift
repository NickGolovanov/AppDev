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
    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var email: String = ""
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @AppStorage("userId") var userId: String = ""
    @State private var profileImageUrl: String = ""

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
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Profile Update"), message: Text(alertMessage),
                        dismissButton: .default(Text("OK")))
                }
            }
            .padding()
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Profile Update"), message: Text(alertMessage),
                dismissButton: .default(Text("OK")))
        }
        .onAppear(perform: fetchUserData)
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
                // You might want to load the profile image if profileImageUrl is not empty
                // This would require additional logic
            } else {
                print(
                    "Document does not exist or error: \(error?.localizedDescription ?? "Unknown error")"
                )
            }
        }
    }

    func saveProfile() {
        guard !userId.isEmpty else {
            alertMessage = "User ID is missing. Cannot save profile."
            showAlert = true
            return
        }
        guard !fullName.isEmpty, !username.isEmpty, !email.isEmpty else {
            alertMessage = "Please fill in all required fields."
            showAlert = true
            return
        }

        // This function will be called to update Firestore after image handling.
        let performFirestoreUpdate = {
            (imageUrlToSave: String, imageUpdateFailed: Bool, imageUploadErrorMessage: String?) in
            self.saveProfileDetails(profileImageUrlToSave: imageUrlToSave) { error in
                if let error = error {
                    if imageUpdateFailed {
                        self.alertMessage =
                            "\(imageUploadErrorMessage ?? "Image upload failed.")"
                    } else {
                        self.alertMessage = "Error saving profile: \(error.localizedDescription)"
                    }
                } else {
                    if imageUpdateFailed {
                        self.alertMessage =
                            "\(imageUploadErrorMessage ?? "Image upload failed.")"
                    } else {
                        self.alertMessage = "Profile updated successfully!"
                    }
                    // Successfully saved, so update the local profileImageUrl state if it changed
                    self.profileImageUrl = imageUrlToSave
                }
                self.showAlert = true
            }
        }

        if let newImageSelected = profileImage {  // User selected a new UIImage
            uploadProfileImage(newImageSelected) { result in
                switch result {
                case .success(let newUrl):
                    // Image uploaded successfully, save with new URL
                    performFirestoreUpdate(newUrl.absoluteString, false, nil)
                case .failure(let uploadError):
                    // Image upload failed. Save other details with the *old* image URL.
                    let uploadFailedMessage =
                        "Image upload failed: \(uploadError.localizedDescription)"
                    print(uploadFailedMessage)  // Also log it for debugging
                    performFirestoreUpdate(self.profileImageUrl, true, uploadFailedMessage)
                }
            }
        } else {
            // No new UIImage selected. Save other details with the existing profileImageUrl.
            performFirestoreUpdate(self.profileImageUrl, false, nil)
        }
    }

    // Renamed from saveUserData and modified to use updateData
    func saveProfileDetails(profileImageUrlToSave: String, completion: @escaping (Error?) -> Void) {
        let userDataToUpdate: [String: Any] = [
            "fullName": fullName,
            "username": username,
            "description": bio,
            "email": email,
            "profileImageUrl": profileImageUrlToSave,
            "joinedEventIds": [],
            "organizedEventIds": [],
        ]

        Firestore.firestore().collection("users").document(userId).updateData(userDataToUpdate) {
            error in
            completion(error)
        }
    }

    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let error = NSError(
                domain: "AppDev.ImageConversion", code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data."])
            print("Image conversion failed: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        let imageName = "\(UUID().uuidString).jpg"
        let storagePath = "profileImages/\(imageName)"
        let storageRef = Storage.storage().reference().child(storagePath)

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    print(
                        "Firebase Storage: downloadURL successful for \(storagePath). URL: \(url.absoluteString)"
                    )
                    completion(.success(url))
                } else {
                    // This case (nil url and nil error) should ideally not happen with Firebase SDKs
                    let unknownError = NSError(
                        domain: "AppDev.FirebaseStorage", code: 1002,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Download URL was nil without an error for \(storagePath)."
                        ])

                    completion(.failure(unknownError))
                }
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
