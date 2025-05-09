import SwiftUI

struct LoginPage: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("PartyPal")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 0.58, green: 0.38, blue: 0.98))
                Spacer()
            }
            .padding()
            .background(Color(red: 0.13, green: 0.13, blue: 0.15))
            
            Spacer().frame(height: 32)
            Spacer()
            // Main Content
            VStack(spacing: 40) {
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
                .frame(width: 280, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 4)
                .padding(.bottom, 24)
            
            VStack(spacing: 12){
            // Login Button
            Button(action: {
                // Handle login action
            }) {
                HStack {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 20))
                    Text("Log in with Student Account")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(white: 0.85))
                .cornerRadius(10)
            }
            .padding(.horizontal, 24)
            
            Text("Use your university Microsoft email to continue")
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
                        Color(red: 0.13, green: 0.38, blue: 0.98)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .background(Color(red: 0.97, green: 0.97, blue: 1.0))
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    LoginPage()
}