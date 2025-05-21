import SwiftUI
import FirebaseFirestore

struct GetTicketView: View {
    let eventName: String
    let date: String
    let location: String
    let price: String
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Get Your Ticket")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 32)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Name")
                    .font(.headline)
                TextField("Enter your name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                Text("Email")
                    .font(.headline)
                TextField("Enter your email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            .padding(.horizontal, 24)
            
            Button(action: {
                buyNow()
            }) {
                Text("Buy Now")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            
            Spacer()
        }
        .navigationTitle("Get Ticket")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func buyNow() {
        // Validation
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertTitle = "Invalid Name"
            alertMessage = "Please enter your name."
            showAlert = true
            return
        }
        guard isValidEmail(email) else {
            alertTitle = "Invalid Email"
            alertMessage = "Please enter a valid email address."
            showAlert = true
            return
        }
        // Save to Firestore
        let db = Firestore.firestore()
        let ticketData: [String: Any] = [
            "name": name,
            "email": email,
            "eventName": eventName,
            "date": date,
            "location": location,
            "price": price,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("tickets").addDocument(data: ticketData) { error in
            if let error = error {
                alertTitle = "Error"
                alertMessage = "Failed to save ticket: \(error.localizedDescription)"
            } else {
                alertTitle = "Ticket Purchased"
                alertMessage = "Thank you, \(name)! Your ticket has been reserved."
                name = ""
                email = ""
            }
            showAlert = true
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES[cd] %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

#Preview {
    GetTicketView(eventName: "Sample Event", date: "21 May 2025, 10:00", location: "Sample Location", price: "€10.00")
} 