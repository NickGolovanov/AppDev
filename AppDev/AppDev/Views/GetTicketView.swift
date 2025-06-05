import FirebaseAuth

import FirebaseFirestore

import SwiftUI

struct GetTicketView: View {
    let eventId: String
    let eventName: String
    let date: String
    let location: String
    let price: String

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @AppStorage("userId") var userId: String = ""

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
                Alert(
                    title: Text(alertTitle), message: Text(alertMessage),
                    dismissButton: .default(Text("OK")))
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

        // Initial ticket data without qrcodeUrl or a predefined ticketId
        let initialTicketData: [String: Any] = [
            "name": name,
            "email": email,
            "eventId": eventId,
            "eventName": eventName,
            "date": date,
            "location": location,
            "price": price,
            "timestamp": FieldValue.serverTimestamp(),
            "used": false,
            "userId": userId,
        ]

        // 1. Create the document with initial data, letting Firestore generate the ID
        var newTicketRef: DocumentReference? = nil
        newTicketRef = db.collection("tickets").addDocument(data: initialTicketData) { error in
            if let error = error {
                self.alertTitle = "Error"
                self.alertMessage = "Failed to create ticket: \(error.localizedDescription)"
                self.showAlert = true
                return
            }

            guard let newTicketID = newTicketRef?.documentID else {
                self.alertTitle = "Error"
                self.alertMessage = "Failed to get new ticket ID."
                self.showAlert = true
                return
            }

            let qrcodeUrl = "https://api.qrserver.com/v1/create-qr-code/?data=\(newTicketID)"

            db.collection("tickets").document(newTicketID).updateData([
                "qrcodeUrl": qrcodeUrl,
                "ticketId": newTicketID,
            ]) { updateError in
                if let updateError = updateError {
                    self.alertTitle = "Error"
                    self.alertMessage =
                        "Failed to update ticket with QR code: \(updateError.localizedDescription)"
                } else {
                    self.alertTitle = "Ticket Purchased"
                    self.alertMessage = "Thank you, \(self.name)! Your ticket has been reserved."
                    self.name = ""
                    self.email = ""

                    // Add event ID to user's joinedEventIds
                    if !self.userId.isEmpty {
                        let userRef = db.collection("users").document(self.userId)
                        userRef.updateData([
                            "joinedEventIds": FieldValue.arrayUnion([self.eventId])
                        ]) { userUpdateError in
                            if let userUpdateError = userUpdateError {
                                print(
                                    "Error updating user joinedEventIds: \(userUpdateError.localizedDescription)"
                                )
                            } else {
                                print("User joinedEventIds updated successfully.")
                            }
                        }
                    }

                    // Create chat document if it doesn't exist
                    let chatData: [String: Any] = [
                        "eventName": self.eventName,
                        "lastMessage": "Welcome to the \(self.eventName) chat!",
                        "lastMessageTime": FieldValue.serverTimestamp(),
                    ]
                    db.collection("chats").document(self.eventId).setData(chatData, merge: true)
                }
                self.showAlert = true
            }
        }
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format: "SELF MATCHES[cd] %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
#Preview {
    GetTicketView(
        eventId: "sampleEventId", eventName: "Sample Event", date: "21 May 2025, 10:00",
        location: "Sample Location", price: "€10.00")
}
