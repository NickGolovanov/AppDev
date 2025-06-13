import FirebaseAuth
import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import Firebase
import FirebaseCore

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showRegistration = false
    
    @State private var isLoggedIn = false
    @State private var vm = AuthenticationView()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @AppStorage("userId") var userId: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)
            Spacer()
            // Main Content
            VStack(spacing: 50) {
                VStack(spacing: 16) {
                    Text("🎉 Welcome to PartyPal")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color(red: 0.27, green: 0.27, blue: 0.36))
                        .multilineTextAlignment(.center)
                    Text("Exclusively for students. Log in to get started.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                // image
                Image("party")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 280, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 4)
                    .padding(.bottom, 24)

                VStack(spacing: 16) {
                    // Email Field
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.horizontal, 24)

                    // Password Field
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                        .padding(.horizontal, 24)

                    // Login Button
                    Button(action: loginUser) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "square.grid.2x2.fill")
                                    .font(.system(size: 20))
                                Text("Log in")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading || !isFormValid)
                    .padding(.horizontal, 24)

                    GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .light)){
                                            vm.signInWithGoogle()
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 80)
                                        .cornerRadius(50)
                                        .padding(.horizontal, 24)
                    // Sign Up Link
                    Button(action: {
                        showRegistration = true
                    }) {
                        Text("Don't have an account? Sign Up")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 8)

                    Text("Use your university email to continue")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.horizontal, 24)
                }
            }
            .frame(maxWidth: .infinity)
            Spacer(minLength: 32)

            // Footer
            HStack {
                Text("© PartyPal 2025 – Built for Students by Students")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.58, green: 0.38, blue: 0.98),
                        Color(red: 0.13, green: 0.38, blue: 0.98),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .background(Color(red: 0.97, green: 0.97, blue: 1.0))
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Login"), message: Text(alertMessage),
                dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showRegistration) {
            RegistrationView()
                .environmentObject(authViewModel)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    private func loginUser() {
        guard isFormValid else { return }

        isLoading = true

        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            isLoading = false

            if let error = error {
                alertMessage = "Login failed: \(error.localizedDescription)"
                showAlert = true
                return
            }

            if let authResult = authResult {
                self.userId = authResult.user.uid
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
