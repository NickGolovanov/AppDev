//
//  EditProfileView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

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
                    ImagePicker(image: $profileImage) // uses your existing ImagePicker returning UIImage
                }

                labeledTextField("Full Name", text: $fullName)
                labeledTextField("Username", text: $username, prefix: "@")
                labeledTextEditor("Description", text: $bio)
                labeledTextField("Email", text: $email, keyboardType: .emailAddress)

                Button(action: saveProfile) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#7131C5"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 20)

            }
            .padding()
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Profile Update"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    func saveProfile() {
        guard !fullName.isEmpty, !username.isEmpty, !email.isEmpty else {
            alertMessage = "Please fill in all required fields."
            showAlert = true
            return
        }

        if let image = profileImage {
            uploadProfileImage(image) { result in
                switch result {
                case .success(let url):
                    saveUserData(profileImageUrl: url.absoluteString)
                case .failure(let error):
                    alertMessage = "Image upload failed: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        } else {
            saveUserData(profileImageUrl: "")
        }
    }

    func saveUserData(profileImageUrl: String) {
        let userData: [String: Any] = [
            "fullName": fullName,
            "username": username,
            "description": bio,
            "email": email,
            "profileImageUrl": profileImageUrl
        ]

        Firestore.firestore().collection("users").document(userId).setData(userData, merge: true) { error in
            alertMessage = error == nil ? "Profile updated successfully!" : "Error saving profile: \(error!.localizedDescription)"
            showAlert = true
        }
    }

    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageConversion", code: 1)))
            return
        }

        let storageRef = Storage.storage().reference().child("profileImages/\(UUID().uuidString).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            storageRef.downloadURL { url, error in
                if let url = url {
                    completion(.success(url))
                } else {
                    completion(.failure(error!))
                }
            }
        }
    }

    func labeledTextField(_ label: String, text: Binding<String>, prefix: String = "", keyboardType: UIKeyboardType = .default) -> some View {
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

