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
    let eventName: String
    let date: String
    let location: String
    let name: String
    let email: String
    let price: String
    let qrcodeUrl: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventName
        case date
        case location
        case name
        case email
        case price
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
            Text(ticket.eventName)
                .font(.headline)
                .fontWeight(.semibold)
            HStack(spacing: 12) {
                Label(ticket.date, systemImage: "calendar")
                    .font(.subheadline)
                Spacer()
            }
            HStack(spacing: 12) {
                Label(ticket.location, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                Spacer()
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Name: ") + Text(ticket.name).fontWeight(.medium)
                Text("Email: ") + Text(ticket.email).fontWeight(.medium)
                Text("Ticket Price: ") + Text(ticket.price).fontWeight(.medium)
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            Spacer(minLength: 8)
            if let url = URL(string: ticket.qrcodeUrl), !ticket.qrcodeUrl.isEmpty {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle().fill(Color.black)
                }
                .frame(width: 100, height: 100)
                .cornerRadius(8)
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
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
