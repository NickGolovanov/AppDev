import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import GoogleSignInSwift
import FirebaseCore

struct RegistrationView: View {
    @State private var email = ""
    @State private var fullName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var authViewModel: AuthViewModel
    
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

                    // Add Google Sign-In Button
                    Button(action: handleGoogleSignIn) {
                       HStack {
                           Image(systemName: "globe") // Or use a Google logo asset if you have one
                           Text("Sign in with Google")
                               .frame(maxWidth: .infinity)
                       }
                       .foregroundColor(.white)
                       .padding()
                       .background(Color.red)
                       .cornerRadius(8)
                    }
                    .disabled(isLoading)
                    .listRowBackground(Color.red)
                }
            }
            .navigationTitle("Registration")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Registration"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func handleGoogleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                alertMessage = "Google Sign-In failed: \(error.localizedDescription)"
                showAlert = true
                return
            }
            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString,
                let accessToken = user.accessToken?.tokenString
            else {
                alertMessage = "Google authentication failed."
                showAlert = true
                return
            }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    alertMessage = "Firebase Sign-In failed: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                // User is signed in with Google
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
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    alertMessage = "Failed to save user data: \(error.localizedDescription)"
                    showAlert = true
                }
                
                isLoading = false
            }
        }
    }
}

#Preview {
    RegistrationView()
        .environmentObject(AuthViewModel())
} 