import FirebaseAuth

import FirebaseFirestore

import SwiftUI

struct GetTicketView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    let eventId: String
    let eventName: String
    let date: String
    let location: String
    let price: String
    
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoading = false
    @AppStorage("userId") var userId: String = ""

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
                        Text(authViewModel.currentUser?.fullName ?? "Loading...")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)

                        Text("Email")
                            .font(.headline)
                        Text(authViewModel.currentUser?.email ?? "Loading...")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 24)

                    // Event Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Event Details")
                            .font(.headline)
                            .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(eventName)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(date)
                                .foregroundColor(.gray)
                            Text(location)
                                .foregroundColor(.gray)
                            Text(price)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    }

                    // Buy Now Button
                    Button(action: {
                        purchaseTicket()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .cornerRadius(12)
                        } else {
                            Text("Buy Now")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Get Ticket")
            .navigationBarTitleDisplayMode(.inline)
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
        guard let user = authViewModel.currentUser else {
            alertTitle = "Error"
            alertMessage = "User information not available. Please try again."
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
            "name": user.fullName,
            "email": user.email,
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
                    self.alertMessage = "Thank you, \(user.fullName)! Your ticket has been reserved."

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
}

#Preview {
    GetTicketView(
        eventId: "sampleEventId", eventName: "Sample Event", date: "21 May 2025, 10:00",
        location: "Sample Location", price: "€10.00")
        .environmentObject(AuthViewModel())
}
