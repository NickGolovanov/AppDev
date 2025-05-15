//
//  ContentView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/3/25.
//

import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth

struct Ticket: Identifiable, Codable {
    let id: String
    let eventId: String
    let qrcodeUrl: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId
        case qrcodeUrl
        case userId
    }
}

struct TicketsView: View {
    @State private var tickets: [Ticket] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView()
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Title
            HStack {
                Text("My Tickets")
                    .font(.title).fontWeight(.heavy)
                Spacer()
            }
            .padding([.horizontal, .top])
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack {
                    Text("Error loading tickets")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if tickets.isEmpty {
                VStack {
                    Text("No tickets found")
                        .font(.headline)
                    Text("Your purchased tickets will appear here")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Tickets List
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(tickets) { ticket in
                            TicketCard(ticket: ticket)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            fetchTickets()
        }
    }
    
    private func fetchTickets() {
        let db = Firestore.firestore()
        db.collection("tickets")
            .addSnapshotListener { snapshot, error in
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    errorMessage = "No tickets found"
                    return
                }
                
                tickets = documents.compactMap { doc in
                    var data = doc.data()
                    data["id"] = doc.documentID
                    return try? Firestore.Decoder().decode(Ticket.self, from: data)
                }
            }
    }
}

struct TicketCard: View {
    let ticket: Ticket
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event ID: \(ticket.eventId)")
                .font(.headline)
                .fontWeight(.semibold)
            Text("QR Code URL: \(ticket.qrcodeUrl)")
                .font(.subheadline)
            Text("User ID: \(ticket.userId)")
                .font(.subheadline)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(.systemGray4).opacity(0.2), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    TicketsView()
}
