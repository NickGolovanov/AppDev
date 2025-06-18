import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI
import Stripe
import StripePaymentSheet
import UIKit

struct IdentifiablePaymentSheet: Identifiable {
    let id = UUID()
    let paymentSheet: PaymentSheet
}

struct GetTicketView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var stripeService = StripeService()
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToEvent = false
    @State private var chatService: ChatService?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Event details section
                VStack(alignment: .leading, spacing: 16) {
                    Text(event.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        Image(systemName: "calendar")
                        Text(event.date)
                    }
                    .foregroundColor(.gray)

                    HStack {
                        Image(systemName: "clock")
                        Text("\(event.startTime) - \(event.endTime)")
                    }
                    .foregroundColor(.gray)

                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text(event.location)
                    }
                    .foregroundColor(.gray)

                    HStack {
                        Image(systemName: "person.2")
                        Text("\(event.attendees)/\(event.maxCapacity) attendees")
                    }
                    .foregroundColor(.gray)

                    if event.price > 0 {
                        HStack {
                            Image(systemName: "eurosign.circle")
                            Text("€\(String(format: "%.2f", event.price))")
                        }
                        .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                // Purchase Button
                Button(action: purchaseTicket) {
                    if stripeService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(event.price > 0 ? "Pay €\(String(format: "%.2f", event.price))" : "Get Free Ticket")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(stripeService.isLoading)
            }
        }
        .background(Color(.systemGray6))
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK") {
                if navigateToEvent {
                    dismiss()
                }
            }
        }
        .onAppear {
            if let user = authViewModel.currentUser {
                name = user.fullName
                email = user.email
            }
            chatService = ChatService(authViewModel: authViewModel)
        }
    }

    private func purchaseTicket() {
        guard !name.isEmpty else {
            alertMessage = "User name is missing. Please log in again."
            showAlert = true
            return
        }
        
        guard !email.isEmpty else {
            alertMessage = "User email is missing. Please log in again."
            showAlert = true
            return
        }

        if event.price > 0 {
            // For paid events, prepare and show payment sheet
            let amount = Int(event.price * 100) // Convert to cents
            stripeService.preparePaymentSheet(amount: amount) { success, errorMessage in
                if success {
                    // Get the current window scene
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let viewController = windowScene.windows.first?.rootViewController else {
                        alertMessage = "Could not present payment sheet"
                        showAlert = true
                        return
                    }
                    
                    // Present the payment sheet
                    stripeService.presentPaymentSheet(from: viewController) { success in
                        if success {
                            createTicket()
                        } else {
                            alertMessage = "Card validation failed. Please try again."
                            showAlert = true
                        }
                    }
                } else {
                    alertMessage = errorMessage ?? "Could not prepare payment. Please try again."
                    showAlert = true
                }
            }
        } else {
            // For free events, create ticket directly
            createTicket()
        }
    }

    private func createTicket() {
        let db = Firestore.firestore()
        let eventId = event.id ?? ""
        let ticketRef = db.collection("tickets").document()
        let ticketData: [String: Any] = [
            "eventId": eventId,
            "eventName": event.title,
            "date": event.date,
            "location": event.location,
            "userId": Auth.auth().currentUser?.uid ?? "",
            "name": name,
            "email": email,
            "price": String(format: "%.2f", event.price),
            "qrcodeUrl": "",
        ]
        
        ticketRef.setData(ticketData) { error in
            if let error = error {
                self.alertMessage = "Failed to create ticket: \(error.localizedDescription)"
                self.showAlert = true
                return
            }
            
            // Use API QR code link
            let qrCodeUrl = "https://api.qrserver.com/v1/create-qr-code/?data=\(ticketRef.documentID)"
            ticketRef.updateData(["qrcodeUrl": qrCodeUrl]) { error in
                if let error = error {
                    self.alertMessage = "Failed to update ticket with QR code: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                // Update event attendees count and user's joined events
                Task {
                    do {
                        try await self.stripeService.handleSuccessfulPayment(
                            eventId: eventId,
                            userId: Auth.auth().currentUser?.uid ?? ""
                        )
                        
                        // Create chat for the event
                        let ticket = Ticket(
                            id: ticketRef.documentID,
                            eventId: eventId,
                            eventName: event.title,
                            date: event.date,
                            location: event.location,
                            name: name,
                            email: email,
                            price: String(format: "%.2f", event.price),
                            qrcodeUrl: qrCodeUrl,
                            userId: Auth.auth().currentUser?.uid ?? ""
                        )
                        try await chatService?.createChatForTicket(ticket: ticket)
                        
                        await MainActor.run {
                            self.alertMessage = "Ticket purchased successfully!"
                            self.showAlert = true
                            self.navigateToEvent = true
                        }
                    } catch {
                        await MainActor.run {
                            self.alertMessage = "Error updating event data: \(error.localizedDescription)"
                            self.showAlert = true
                        }
                    }
                }
            }
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("M", forKey: "inputCorrectionLevel")
        if let qrImage = qrFilter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledQrImage = qrImage.transformed(by: transform)
            return UIImage(ciImage: scaledQrImage)
        }
        return nil
    }
}

#Preview {
    GetTicketView(event: Event(
        id: "preview",
        title: "Summer Beach Party",
        date: "2024-07-15",
        endTime: "23:00",
        startTime: "18:00",
        location: "Amsterdam Beach",
        imageUrl: "https://example.com/beach-party.jpg",
        attendees: 50,
        category: "Party",
        price: 15.0,
        maxCapacity: 100,
        description: "Join us for an amazing beach party!"
    ))
    .environmentObject(AuthViewModel())
}
