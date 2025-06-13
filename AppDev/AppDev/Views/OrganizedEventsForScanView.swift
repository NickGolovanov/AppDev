//
//  OrganizedEventsForScanView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/14/24.
//

import SwiftUI
import FirebaseFirestore

struct OrganizedEventsForScanView: View {
    @AppStorage("userId") var userId: String = ""
    @State private var organizedEvents: [Event] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select an Event to Scan QR Code")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack {
                    Text("Error loading organized events")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if organizedEvents.isEmpty {
                Spacer()
                Text("You haven't organized any events yet, or all events have expired/reached capacity.")
                    .foregroundColor(.gray)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(organizedEvents) { event in
                            eventScanCard(event: event)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Scan QR Code")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: fetchOrganizedEventsForScan)
    }

    func eventScanCard(event: Event) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#E9DDFD"))
                    .frame(width: 40, height: 40)

                if let imageUrl = URL(string: event.imageUrl), !event.imageUrl.isEmpty {
                    AsyncImage(url: imageUrl) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                    } placeholder: {
                        Image(systemName: "calendar")
                            .foregroundColor(Color(hex: "#7131C5"))
                    }
                } else {
                    Image(systemName: "calendar")
                        .foregroundColor(Color(hex: "#7131C5"))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("\(event.formattedDate), \(event.formattedTime)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            NavigationLink(destination: QRCodeScannerView(eventName: event.title, eventId: event.id ?? "")) {
                Text("Scan")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color(hex: "#7131C5"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func fetchOrganizedEventsForScan() {
        guard !userId.isEmpty else {
            self.isLoading = false
            self.errorMessage = "User not logged in."
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { userDocument, userError in
            if let userError = userError {
                self.errorMessage = "Error fetching user data: \(userError.localizedDescription)"
                self.isLoading = false
                return
            }

            guard let userDocument = userDocument, userDocument.exists, let userData = userDocument.data() else {
                self.errorMessage = "User document not found."
                self.isLoading = false
                return
            }

            let organizedEventIds = userData["organizedEventIds"] as? [String] ?? []

            guard !organizedEventIds.isEmpty else {
                self.organizedEvents = []
                self.isLoading = false
                return
            }

            db.collection("events").whereField(FieldPath.documentID(), in: organizedEventIds)
                .getDocuments { eventSnapshot, eventError in
                    self.isLoading = false
                    if let eventError = eventError {
                        self.errorMessage = "Error fetching organized events: \(eventError.localizedDescription)"
                        return
                    }

                    guard let eventDocuments = eventSnapshot?.documents else {
                        self.errorMessage = "No organized events found."
                        return
                    }

                    let fetchedEvents = eventDocuments.compactMap { doc -> Event? in
                        do {
                            let event = try doc.data(as: Event.self)
                            return event
                        } catch {
                            print("Error decoding event \(doc.documentID): \(error.localizedDescription)")
                            return nil
                        }
                    }

                    // Filter out expired and full events
                    let filtered = fetchedEvents.filter { event in
                        let dateFormatter = ISO8601DateFormatter()
                        if let eventDate = dateFormatter.date(from: event.date) {
                            let isExpired = eventDate < Date()
                            let isFull = event.attendees >= event.maxCapacity
                            return !isExpired && !isFull
                        }
                        return false // Exclude if date format is invalid
                    }
                    self.organizedEvents = filtered
                }
        }
    }
}

#Preview {
    OrganizedEventsForScanView()
} 