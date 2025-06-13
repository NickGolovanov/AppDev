import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

struct GetTicketView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var navigateToEvent = false
    @State private var chatService: ChatService?

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
                            if isLoading {
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
                        .disabled(isLoading)
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
        
        isLoading = true
        
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
            "status": "active",
            "createdAt": Timestamp(date: Date())
        ]
        ticketRef.setData(ticketData) { error in
            if let error = error {
                isLoading = false
                alertMessage = "Failed to purchase ticket: \(error.localizedDescription)"
                showAlert = true
                return
            }
            // Use API QR code link instead of generating/uploading image
            let qrCodeUrl = "https://api.qrserver.com/v1/create-qr-code/?data=\(ticketRef.documentID)"
            ticketRef.updateData(["qrcodeUrl": qrCodeUrl]) { error in
                if let error = error {
                    isLoading = false
                    alertMessage = "Failed to update ticket with QR code: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                // Update event attendees count
                let eventRef = db.collection("events").document(eventId)
                eventRef.updateData([
                    "attendees": FieldValue.increment(Int64(1))
                ]) { error in
                    if let error = error {
                        print("Error updating attendees count: \(error.localizedDescription)")
                    }
                }
                // Update user's joined events
                if let userId = Auth.auth().currentUser?.uid {
                    let userRef = db.collection("users").document(userId)
                    userRef.updateData([
                        "joinedEventIds": FieldValue.arrayUnion([eventId])
                    ]) { error in
                        if let error = error {
                            print("Error updating user's joined events: \(error.localizedDescription)")
                        }
                    }
                }
                // Create chat for the event
                Task {
                    do {
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
                            userId: Auth.auth().currentUser?.uid ?? "",
                            status: .active
                        )
                        try await chatService?.createChatForTicket(ticket: ticket)
                    } catch {
                        print("Error creating chat: \(error.localizedDescription)")
                    }
                }
                isLoading = false
                alertMessage = "Ticket purchased successfully!"
                showAlert = true
                navigateToEvent = true
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
        description: "Join us for an amazing beach party!",
        latitude: 52.3702,
        longitude: 4.8952
    ))
    .environmentObject(AuthViewModel())
}
