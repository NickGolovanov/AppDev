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
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var isProcessing = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var stripeService = StripeService()
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var navigateToEvent = false
    @State private var chatService: ChatService?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Event Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text(event.title)
                                .font(.title2)
                                .fontWeight(.bold)

                            HStack {
                                Image(systemName: "calendar")
                                Text(event.formattedDate)
                            }
                            .foregroundColor(.gray)

                            HStack {
                                Image(systemName: "clock")
                                Text("\(event.formattedTime) - \(event.formattedEndTime)")
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
                        Button(action: {
                            Task {
                                await handlePayment()
                            }
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Get Ticket")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(stripeService.isLoading || isProcessing)
                    }
                    .padding()
                }
            }
            .navigationTitle("Get Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGray6))
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(isSuccess ? "Success!" : "Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if isSuccess {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
        .onAppear {
            if event.price > 0 {
                preparePayment()
            }
            if let user = authViewModel.currentUser {
                name = user.fullName
                email = user.email
            }
            chatService = ChatService(authViewModel: authViewModel)
        }
    }
    
    private func preparePayment() {
        let amount = Int(event.price * 100) // Convert to cents
        stripeService.preparePaymentSheet(amount: amount) { success, error in
            if !success {
                showingAlert = true
                alertMessage = error ?? "Failed to prepare payment"
            }
        }
    }
    
    private func handlePayment() async {
        isProcessing = true

        // Handle payment for paid events
        if event.price > 0 {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let viewController = windowScene.windows.first?.rootViewController else {
                alertMessage = "Could not present payment sheet"
                showingAlert = true
                isProcessing = false
                return
            }
            
            let success = await stripeService.presentPaymentSheet(from: viewController)
            
            if !success {
                alertMessage = "Payment failed or was cancelled"
                showingAlert = true
                isProcessing = false
                return
            }
        }

        // Create ticket and update database
        do {
            guard let userId = authViewModel.currentUser?.id else {
                alertMessage = "You must be logged in to purchase a ticket."
                isProcessing = false
                showingAlert = true
                return
            }
            
            guard let eventId = event.id else {
                alertMessage = "Event ID is missing."
                isProcessing = false
                showingAlert = true
                return
            }
            
            // Handle successful payment in StripeService (updates attendees, etc.)
            try await stripeService.handleSuccessfulPayment(eventId: eventId, userId: userId)
            
            // Create ticket in Firestore
            let db = Firestore.firestore()
            let ticketRef = db.collection("tickets").document()
            let qrCodeUrl = "https://api.qrserver.com/v1/create-qr-code/?data=\(ticketRef.documentID)"
            
            let ticketData: [String: Any] = [
                "eventId": eventId,
                "eventName": event.title,
                "date": event.date,
                "location": event.location,
                "userId": userId,
                "name": name,
                "email": email,
                "price": String(format: "%.2f", event.price),
                "qrcodeUrl": qrCodeUrl,
                "status": "active",
                "createdAt": Timestamp(date: Date())
            ]
            
            try await ticketRef.setData(ticketData)
            
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
                userId: userId,
                status: .active
            )
            try await chatService?.createChatForTicket(ticket: ticket)
            
            isSuccess = true
            alertMessage = "Payment successful! Your ticket has been confirmed."
            
        } catch {
            alertMessage = "Payment processed but failed to update ticket information: \(error.localizedDescription)"
        }
        
        isProcessing = false
        showingAlert = true
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
        description: "Join us for an amazing beach party!",
        latitude: 52.3702,
        longitude: 4.8952
    ))
    .environmentObject(AuthViewModel())
}
