import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CancelEventView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @State private var cancellationReason = ""
    @State private var selectedReason = "Other"
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let predefinedReasons = [
        "Venue unavailable",
        "Weather conditions",
        "Low attendance",
        "Personal emergency",
        "Technical issues",
        "Safety concerns",
        "Other"
    ]
    
    var onEventCancelled: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Cancel Event")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Are you sure you want to cancel '\(event.title)'?")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Reason Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reason for cancellation")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(predefinedReasons, id: \.self) { reason in
                            HStack {
                                Button(action: {
                                    selectedReason = reason
                                }) {
                                    HStack {
                                        Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedReason == reason ? .purple : .gray)
                                        Text(reason)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional details (optional)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Provide more details about the cancellation...", text: $cancellationReason, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // important message after cancelling
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Important Information")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("• All attendees will be notified\n• Tickets will be refunded automatically\n• This action cannot be undone")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: cancelEvent) {
                        if isSubmitting {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Cancelling Event...")
                            }
                        } else {
                            Text("Cancel Event")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(isSubmitting)
                    
                    Button("Keep Event") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    .disabled(isSubmitting)
                }
            }
            .padding(24)
            .navigationTitle("Cancel Event")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func cancelEvent() {
        guard let eventId = event.id,
              let currentUserId = Auth.auth().currentUser?.uid else {
            showError(message: "Unable to cancel event. Please try again.")
            return
        }
        
        isSubmitting = true
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Update event status to cancelled
        let eventRef = db.collection("events").document(eventId)
        batch.updateData([
            "status": "cancelled",
            "cancellationReason": selectedReason,
            "cancellationDetails": cancellationReason.isEmpty ? nil : cancellationReason,
            "cancelledAt": Timestamp(),
            "cancelledBy": currentUserId
        ], forDocument: eventRef)
        
        // Create cancellation record
        let cancellationRef = db.collection("eventCancellations").document()
        batch.setData([
            "eventId": eventId,
            "eventTitle": event.title,
            "reason": selectedReason,
            "details": cancellationReason.isEmpty ? nil : cancellationReason,
            "cancelledBy": currentUserId,
            "cancelledAt": Timestamp(),
            "attendeesCount": event.attendees
        ], forDocument: cancellationRef)
        
        batch.commit { error in
            isSubmitting = false
            
            if let error = error {
                showError(message: "Failed to cancel event: \(error.localizedDescription)")
                return
            }
            
            // Success - notify attendees and handle refunds
            Task {
                await notifyAttendeesOfCancellation(eventId: eventId)
                await processRefunds(eventId: eventId)
            }
            
            onEventCancelled()
            dismiss()
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    private func notifyAttendeesOfCancellation(eventId: String) async {
        // This would integrate with its notification system
        // For now, I wil just log it
        print("📧 Notifying attendees of event cancellation for event: \(eventId)")
        
        // I also try to implement push notification or email notifications here
        let db = Firestore.firestore()
        
        do {
            // Get all tickets for this event
            let ticketsSnapshot = try await db.collection("tickets")
                .whereField("eventId", isEqualTo: eventId)
                .whereField("status", isEqualTo: "active")
                .getDocuments()
            
            // Create notification records for each attendee
            let batch = db.batch()
            
            for ticketDoc in ticketsSnapshot.documents {
                if let userId = ticketDoc.data()["userId"] as? String {
                    let notificationRef = db.collection("notifications").document()
                    batch.setData([
                        "userId": userId,
                        "type": "event_cancelled",
                        "title": "Event Cancelled",
                        "message": "Unfortunately, '\(event.title)' has been cancelled. You will receive a full refund.",
                        "eventId": eventId,
                        "createdAt": Timestamp(),
                        "read": false
                    ], forDocument: notificationRef)
                }
            }
            
            try await batch.commit()
            print("✅ Cancellation notifications sent to attendees")
            
        } catch {
            print("❌ Error sending notifications: \(error.localizedDescription)")
        }
    }
    
    private func processRefunds(eventId: String) async {
        // This would integrate with your payment system
        print("Processing refunds for event: \(eventId)")
        
        let db = Firestore.firestore()
        
        do {
            // Get all active tickets for this event
            let ticketsSnapshot = try await db.collection("tickets")
                .whereField("eventId", isEqualTo: eventId)
                .whereField("status", isEqualTo: "active")
                .getDocuments()
            
            let batch = db.batch()
            
            for ticketDoc in ticketsSnapshot.documents {
                // Update ticket status to refunded
                batch.updateData([
                    "status": "refunded",
                    "refundedAt": Timestamp(),
                    "refundReason": "event_cancelled"
                ], forDocument: ticketDoc.reference)
                
                // Create refund record
                let refundRef = db.collection("refunds").document()
                let ticketData = ticketDoc.data()
                batch.setData([
                    "ticketId": ticketDoc.documentID,
                    "eventId": eventId,
                    "userId": ticketData["userId"] as? String ?? "",
                    "amount": ticketData["amount"] as? Double ?? 0.0,
                    "reason": "event_cancelled",
                    "status": "processed",
                    "processedAt": Timestamp()
                ], forDocument: refundRef)
            }
            
            try await batch.commit()
            print("✅ Refunds processed for all attendees")
            
        } catch {
            print("❌ Error processing refunds: \(error.localizedDescription)")
        }
    }
}

#Preview {
    CancelEventView(
        event: Event(
            id: "1",
            title: "Sample Event",
            date: "2024-01-01T10:00:00Z",
            endTime: "2024-01-01T22:00:00Z",
            startTime: "2024-01-01T10:00:00Z",
            location: "Sample Location",
            imageUrl: "",
            attendees: 25,
            category: "Party",
            price: 15.0,
            maxCapacity: 100,
            description: "Sample description"
        ),
        onEventCancelled: {}
    )
}