import FirebaseAuth

import FirebaseFirestore

import SwiftUI

struct GetTicketView: View {
    @Environment(\.dismiss) private var dismiss
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
    @State private var isLoading = false
    @AppStorage("userId") var userId: String = ""
    @State private var navigateToEvent = false

    var body: some View {
        NavigationStack {
            ScrollView {
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
                        purchaseTicket()
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
                }
                .padding()
            }
            .navigationTitle("Get Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToEvent) {
                EventView(eventId: eventId)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertTitle == "Ticket Purchased" {
                            dismiss()
                        }
                    }
                )
            }
        }
    }

    func purchaseTicket() {
        guard !name.isEmpty, !email.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Please fill in all fields."
            showAlert = true
            return
        }

        isLoading = true
        let db = Firestore.firestore()
        let newTicketID = UUID().uuidString

        let ticketData: [String: Any] = [
            "eventId": eventId,
            "eventName": eventName,
            "date": date,
            "location": location,
            "price": price,
            "name": name,
            "email": email,
            "userId": userId,
            "createdAt": FieldValue.serverTimestamp(),
        ]

        db.collection("tickets").document(newTicketID).setData(ticketData) { error in
            if let error = error {
                self.alertTitle = "Error"
                self.alertMessage = "Failed to create ticket: \(error.localizedDescription)"
                self.showAlert = true
                self.isLoading = false
                return
            }

            let qrcodeUrl = "https://api.qrserver.com/v1/create-qr-code/?data=\(newTicketID)"

            db.collection("tickets").document(newTicketID).updateData([
                "qrcodeUrl": qrcodeUrl,
                "ticketId": newTicketID,
            ]) { updateError in
                if let updateError = updateError {
                    self.alertTitle = "Error"
                    self.alertMessage = "Failed to update ticket with QR code: \(updateError.localizedDescription)"
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
                                print("Error updating user joinedEventIds: \(userUpdateError.localizedDescription)")
                            } else {
                                print("User joinedEventIds updated successfully.")
                                // Dismiss the view after successful ticket purchase
                                DispatchQueue.main.async {
                                    self.dismiss()
                                }
                            }
                        }
                    }
                }
                self.isLoading = false
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
