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
        VStack(spacing: 20) {
            Text("Get Your Ticket")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Event: \(event.title)")
                .font(.headline)
            
            Text("Price: €\(event.price)")
                .font(.title2)
                .foregroundColor(.green)
            
            if isProcessing {
                ProgressView("Processing payment...")
            } else {
                Button(action: {
                    Task {
                        await handlePayment()
                    }
                }) {
                    Text("Pay Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(stripeService.isLoading)
            }
        }
        .padding()
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
        .onAppear {
            preparePayment()
            if let user = authViewModel.currentUser {
                name = user.fullName
                email = user.email
                chatService = ChatService(currentUser: user)
            }
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
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let viewController = windowScene.windows.first?.rootViewController else {
            showingAlert = true
            alertMessage = "Could not present payment sheet"
            return
        }
        
        isProcessing = true
        
        let success = await stripeService.presentPaymentSheet(from: viewController)
        
        if success {
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
                
                // Update Firestore
                try await stripeService.handleSuccessfulPayment(eventId: eventId, userId: userId)
                
                // Create chat for the event
                let ticket = Ticket(
                    id: eventId,
                    eventId: eventId,
                    eventName: event.title,
                    date: event.date,
                    location: event.location,
                    name: name,
                    email: email,
                    price: String(format: "%.2f", event.price),
                    qrcodeUrl: "",
                    userId: userId
                )
                try await chatService?.createChatForTicket(ticket: ticket)
                
                isSuccess = true
                alertMessage = "Payment successful! Your ticket has been confirmed."
            } catch {
                alertMessage = "Payment processed but failed to update ticket information: \(error.localizedDescription)"
            }
        } else {
            alertMessage = "Payment failed or was cancelled"
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
        description: "Join us for an amazing beach party!"
    ))
    .environmentObject(AuthViewModel())
}
