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

    // Image upload states
    @StateObject private var imageUploadService = ImageUploadService.shared
    @State private var selectedImage: UIImage?
    @State private var uploadError: String?
    @State private var isImageUploaded = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Image Section with Upload
                VStack(spacing: 16) {
                    ZStack {
                        // Profile Image Display
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                .shadow(radius: 5)
                        } else if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                .shadow(radius: 5)
                        } else if !profileImageUrl.isEmpty, let url = URL(string: profileImageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        ProgressView()
                                            .tint(Color(hex: "#7131C5"))
                                    )
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .shadow(radius: 5)
                        } else {
                            Circle()
                                .fill(Color(hex: "#7131C5"))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Text(String(fullName.prefix(1)).uppercased())
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                .shadow(radius: 5)
                        }
                        
                        // Upload progress overlay
                        if imageUploadService.isUploading {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    VStack(spacing: 8) {
                                        ProgressView(value: imageUploadService.uploadProgress)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.2)
                                        Text("\(Int(imageUploadService.uploadProgress * 100))%")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                )
                        }
                    }
                    .onTapGesture {
                        if !imageUploadService.isUploading {
                            showImagePicker = true
                        }
                    }
                    
                    // Upload Controls
                    VStack(spacing: 12) {
                        // Select/Change Image Button
                        Button(action: {
                            showImagePicker = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                Text(selectedImage != nil || profileImage != nil || !profileImageUrl.isEmpty ? "Change Photo" : "Add Photo")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "#7131C5"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(hex: "#7131C5"), lineWidth: 1.5)
                            )
                        }
                        .disabled(imageUploadService.isUploading)
                        
                        // Upload Button (only show when image is selected but not uploaded)
                        if selectedImage != nil && !imageUploadService.isUploading && !isImageUploaded {
                            Button(action: uploadImage) {
                                HStack(spacing: 8) {
                                    Image(systemName: "icloud.and.arrow.up")
                                    Text("Upload Image")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#7131C5"))
                                .cornerRadius(25)
                            }
                        }
                        
                        // Upload Status
                        if imageUploadService.isUploading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Uploading image...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        } else if isImageUploaded {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Image uploaded successfully!")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        // Error message
                        if let uploadError = uploadError {
                            Text(uploadError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
                
                // Form Fields
                VStack(spacing: 20) {
                    labeledTextField("Full Name", text: $fullName)
                    labeledTextField("Username", text: $username, prefix: "@")
                    labeledTextEditor("Description", text: $bio)
                    labeledTextField("Email", text: $email, keyboardType: .emailAddress)
                }
                
                // Save Button
                Button(action: saveProfile) {
                    HStack {
                        if imageUploadService.isUploading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("Uploading...")
                        } else {
                            Text("Save Changes")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        imageUploadService.isUploading 
                            ? Color.gray 
                            : Color(hex: "#7131C5")
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(imageUploadService.isUploading)
                .padding(.top, 30)
            }
            .padding()
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                if profileUpdatedAndReadyToDismiss {
                    print("EditProfileView: Dismissing view via dismiss() after OK.")
                    dismiss()
                }
            }
        } message: {
            Text("Profile updated successfully!")
        }
        .alert("Upload Error", isPresented: .constant(uploadError != nil)) {
            Button("OK") {
                uploadError = nil
            }
        } message: {
            Text(uploadError ?? "")
        }
        .onAppear(perform: fetchUserData)
        .onChange(of: selectedImage) { _ in
            if selectedImage != nil {
                isImageUploaded = false
                uploadError = nil
            }
        }
    }

    // MARK: - Functions
    
    func uploadImage() {
        guard let image = selectedImage else { return }
        
        uploadError = nil
        
        imageUploadService.uploadImage(image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let imageURL):
                    self.profileImageUrl = imageURL
                    self.profileImage = image
                    self.selectedImage = nil
                    self.isImageUploaded = true
                    print("✅ Profile image uploaded: \(imageURL)")
                    
                case .failure(let error):
                    self.uploadError = error.localizedDescription
                    print("❌ Upload failed: \(error)")
                }
            }
        }
    }

    func saveProfile() {
        guard !userId.isEmpty else { 
            uploadError = "User ID not found"
            return 
        }
        guard !fullName.isEmpty, !username.isEmpty, !email.isEmpty else { 
            uploadError = "Please fill in all required fields"
            return 
        }

        let userDataToUpdate: [String: Any] = [
            "fullName": fullName,
            "username": username,
            "description": bio,
            "email": email,
            "profileImageUrl": profileImageUrl
        ]

        Firestore.firestore().collection("users").document(userId).updateData(userDataToUpdate) { error in
            DispatchQueue.main.async {
                if error == nil {
                    self.profileUpdatedAndReadyToDismiss = true
                    print("EditProfileView: Profile saved successfully. Showing success alert.")
                    self.showSuccessAlert = true
                } else {
                    self.uploadError = "Failed to save profile: \(error?.localizedDescription ?? "unknown error")"
                    print("EditProfileView: Error saving profile: \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }

    func fetchUserData() {
        guard !userId.isEmpty else { return }

        Firestore.firestore().collection("users").document(userId).getDocument { document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    let data = document.data()
                    self.fullName = data?["fullName"] as? String ?? ""
                    self.username = data?["username"] as? String ?? ""
                    self.bio = data?["description"] as? String ?? ""
                    self.email = data?["email"] as? String ?? ""
                    self.profileImageUrl = data?["profileImageUrl"] as? String ?? ""
                } else {
                    self.uploadError = "Failed to load profile data"
                }
            }
        }
    }

    func labeledTextField(
        _ label: String, text: Binding<String>, prefix: String = "",
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            TextField(prefix, text: text)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .keyboardType(keyboardType)
        }
    }

    func labeledTextEditor(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: text)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .frame(height: 100)
                
                if text.wrappedValue.isEmpty {
                    Text("Tell us about yourself...")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - ImagePicker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    EditProfileView()
}