import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegistrationView: View {
    @State private var email = ""
    @State private var fullName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var navigateToMainTab = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Security")) {
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                
                Section {
                    Button(action: registerUser) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Register")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                    .listRowBackground(isFormValid ? Color.blue : Color.gray)
                }
            }
            .navigationTitle("Registration")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Registration"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .fullScreenCover(isPresented: $navigateToMainTab) {
                MainTabView()
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !fullName.isEmpty && !password.isEmpty && password == confirmPassword && password.count >= 6
    }
    
    private func registerUser() {
        guard isFormValid else { return }
        
        isLoading = true
        
        // Check if email already exists
        Auth.auth().fetchSignInMethods(forEmail: email) { methods, error in
            if let error = error {
                alertMessage = "Error checking email: \(error.localizedDescription)"
                showAlert = true
                isLoading = false
                return
            }
            
            if let methods = methods, !methods.isEmpty {
                alertMessage = "Email already exists"
                showAlert = true
                isLoading = false
                return
            }
            
            // Create user with Firebase Auth
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    alertMessage = "Registration failed: \(error.localizedDescription)"
                    showAlert = true
                    isLoading = false
                    return
                }
                
                guard let user = authResult?.user else {
                    alertMessage = "Failed to create user"
                    showAlert = true
                    isLoading = false
                    return
                }
                
                // Create user document in Firestore
                let db = Firestore.firestore()
                let userData = User(
                    email: email,
                    fullName: fullName,
                    password: "" // We don't store the actual password, Firebase handles this
                )
                
                do {
                    try db.collection("users").document(user.uid).setData(from: userData)
                    alertMessage = "Registration successful!"
                    showAlert = true
                    isLoading = false
                    // Navigate to MainTabView after successful registration
                    navigateToMainTab = true
                } catch {
                    alertMessage = "Failed to save user data: \(error.localizedDescription)"
                    showAlert = true
                    isLoading = false
                }
            }
        }
    }
} 