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
    let eventName: String
    let date: String
    let location: String
    let name: String
    let email: String
    let price: String
    let qrcodeUrl: String
    let userId: String
    var status: TicketStatus
    
    enum TicketStatus: String, Codable {
        case active
        case used
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId
        case eventName
        case date
        case location
        case name
        case email
        case price
        case qrcodeUrl
        case userId
        case status
    }
    
    var formattedDate: String {
        let isoFormatter = ISO8601DateFormatter()
        if let dateObj = isoFormatter.date(from: self.date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM yyyy"
            return formatter.string(from: dateObj)
        }
        return self.date
    }
}

struct TicketsView: View {
    @State private var tickets: [Ticket] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedFilter: TicketFilter = .active
    
    enum TicketFilter {
        case active
        case used
    }
    
    var filteredTickets: [Ticket] {
        switch selectedFilter {
        case .active:
            return tickets.filter { $0.status == .active }
        case .used:
            return tickets.filter { $0.status == .used }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HeaderView()
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Title and Filter
                VStack(spacing: 16) {
                    HStack {
                        Text("My Tickets")
                            .font(.title).fontWeight(.heavy)
                        Spacer()
                    }
                    
                    // Filter Picker
                    Picker("Filter", selection: $selectedFilter) {
                        Text("Active").tag(TicketFilter.active)
                        Text("Used").tag(TicketFilter.used)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
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
                } else if filteredTickets.isEmpty {
                    VStack {
                        Text("No tickets found")
                            .font(.headline)
                        Text(selectedFilter == .active ? "You don't have any active tickets" : "You don't have any used tickets")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Tickets List
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredTickets) { ticket in
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
    }
    
    private func fetchTickets() {
        guard let currentUser = Auth.auth().currentUser else {
            self.tickets = []
            self.isLoading = false
            self.errorMessage = "User not logged in."
            return
        }
        let db = Firestore.firestore()
        db.collection("tickets")
            .whereField("userId", isEqualTo: currentUser.uid)
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
                    // Set default status if not present
                    if data["status"] == nil {
                        data["status"] = Ticket.TicketStatus.active.rawValue
                    }
                    return try? Firestore.Decoder().decode(Ticket.self, from: data)
                }
            }
    }
}

struct TicketCard: View {
    let ticket: Ticket
    @State private var showQRCodeSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(ticket.eventName)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                // Status Badge
                Text(ticket.status.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        ticket.status == .active ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
                    )
                    .foregroundColor(
                        ticket.status == .active ? .green : .red
                    )
                    .cornerRadius(8)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(ticket.eventName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                HStack {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                    Text(ticket.formattedDate)
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)

                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.subheadline)
                    Text(ticket.location)
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
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
                .onTapGesture {
                    showQRCodeSheet = true
                }
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
        .sheet(isPresented: $showQRCodeSheet) {
            EnlargedQRCodeView(qrCodeUrl: ticket.qrcodeUrl)
        }
    }
}

struct EnlargedQRCodeView: View {
    let qrCodeUrl: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            if let url = URL(string: qrCodeUrl), !qrCodeUrl.isEmpty {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle().fill(Color.black)
                }
                .frame(width: 300, height: 300)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 300, height: 300)
                    .cornerRadius(8)
            }
            Button("Close") {
                dismiss()
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    TicketsView()
}
