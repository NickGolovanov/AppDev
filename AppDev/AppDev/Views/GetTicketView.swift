import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI
import Stripe
import StripePaymentSheet

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
    @State private var isLoading = false
    @State private var navigateToEvent = false
    @State private var chatService: ChatService?
    
    // Stripe related state variables
    @State private var identifiablePaymentSheet: IdentifiablePaymentSheet?
    @State private var isProcessingPayment = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HeaderView(title: "Get Ticket", showBackButton: true)
                    .padding()
                    .background(Color.white)

                ScrollView {
                    VStack(spacing: 24) {
                        // Event Image (REMOVED)
                        // if let imageUrl = event.imageUrl {
                        //     AsyncImage(url: URL(string: imageUrl)) { image in
                        //         image
                        //             .resizable()
                        //             .aspectRatio(contentMode: .fill)
                        //     } placeholder: {
                        //         Rectangle()
                        //             .fill(Color.gray.opacity(0.2))
                        //     }
                        //     .frame(height: 200)
                        //     .clipped()
                        // }

                        // Event Details
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
                            if isLoading || isProcessingPayment {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Get Ticket")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .disabled(isLoading || isProcessingPayment)
                    }
                    .padding(.bottom)
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
            .sheet(item: $identifiablePaymentSheet) { wrapper in
                VStack {
                    PaymentSheet.PaymentButton(
                        paymentSheet: wrapper.paymentSheet,
                        onCompletion: onPaymentCompletion
                    ) {
                        Text("Pay €\(String(format: "%.2f", event.price))")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            if let user = authViewModel.currentUser {
                name = user.fullName
                email = user.email
            } else {
                print("[GetTicketView] AuthViewModel currentUser is nil onAppear")
            }
            chatService = ChatService(authViewModel: authViewModel)
        }
    }

    private func preparePayment() async {
        isProcessingPayment = true
        
        do {
            let clientSecret = try await stripeService.createPaymentIntent(
                amount: Int(event.price * 100), // Convert to cents
                currency: "eur",
                eventId: event.id ?? "",
                userId: Auth.auth().currentUser?.uid ?? ""
            )
            
            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Your App Name"
            configuration.allowsDelayedPaymentMethods = true
            
            let sheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
            self.identifiablePaymentSheet = IdentifiablePaymentSheet(paymentSheet: sheet)
            isProcessingPayment = false
        } catch {
            alertMessage = "Failed to prepare payment: \(error.localizedDescription)"
            showAlert = true
            isProcessingPayment = false
        }
    }
    
    private func onPaymentCompletion(result: PaymentSheetResult) {
        switch result {
        case .completed:
            // Payment successful, proceed with ticket creation
            createTicket()
        case .failed(let error):
            alertMessage = "Payment failed: \(error.localizedDescription)"
            showAlert = true
        case .canceled:
            alertMessage = "Payment was canceled"
            showAlert = true
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
            
            // Use API QR code link instead of generating/uploading image
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
                        
                        self.alertMessage = "Ticket purchased successfully!"
                        self.showAlert = true
                        self.navigateToEvent = true
                    } catch {
                        self.alertMessage = "Error updating event data: \(error.localizedDescription)"
                        self.showAlert = true
                    }
                }
            }
        }
    }

    private func purchaseTicket() {
        guard !name.isEmpty else {
            alertMessage = "User name is missing. Please log in again."
            print("[GetTicketView] User name is missing. Aborting ticket creation.")
            showAlert = true
            return
        }
        
        guard !email.isEmpty else {
            alertMessage = "User email is missing. Please log in again."
            print("[GetTicketView] User email is missing. Aborting ticket creation.")
            showAlert = true
            return
        }
        
        // Start payment process
        Task {
            await preparePayment()
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
