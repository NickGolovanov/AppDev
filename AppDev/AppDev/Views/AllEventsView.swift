//
//  AllEventsView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

import SwiftUI
import FirebaseFirestore

struct AllEventsView: View {
    @AppStorage("userId") var userId: String = ""
    @State private var joinedEvents: [Event] = []
    @State private var organizedEvents: [Event] = []
    @State private var allEvents: [Event] = [] // To hold combined events
    @State private var filteredEvents: [Event] = [] // To hold currently displayed events
    @State private var selectedFilter: EventFilter = .all // State for filter selection
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    enum EventFilter {
        case all
        case joined
        case organized
    }

    var body: some View {
        VStack {
            Picker("Filter", selection: $selectedFilter) {
                Text("All").tag(EventFilter.all)
                Text("Joined").tag(EventFilter.joined)
                Text("Organized").tag(EventFilter.organized)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedFilter) { _ in
                applyFilter()
            }

            if isLoading {
                ProgressView()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else if filteredEvents.isEmpty {
                Text("No events found for this filter.")
                    .foregroundColor(.gray)
            } else {
                List(filteredEvents) { event in
                    NavigationLink(destination: EventView(eventId: event.id)) {
                        EventRow(event: event) // Use a helper view for event row
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("My Events")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: fetchAllEvents)
    }

    // Helper view for displaying an event row in the list
    struct EventRow: View {
        let event: Event

        var body: some View {
            HStack(spacing: 12) {
                // Use AsyncImage for event image if available, otherwise use a placeholder icon
                if let imageUrl = URL(string: event.imageUrl), !event.imageUrl.isEmpty {
                    AsyncImage(url: imageUrl) {
                         image in image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                    } placeholder: {
                        Image(systemName: "calendar") // Placeholder icon
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                    }
                } else {
                    Image(systemName: "calendar") // Default icon if no image URL
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("\(event.formattedDate), \(event.formattedTime)") // Use formatted date and time
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    func fetchAllEvents() {
        guard !userId.isEmpty else {
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        userRef.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let joinedEventIds = data?["joinedEventIds"] as? [String] ?? []
                let organizedEventIds = data?["organizedEventIds"] as? [String] ?? []

                let dispatchGroup = DispatchGroup()

                if !joinedEventIds.isEmpty {
                    dispatchGroup.enter()
                    db.collection("events").whereField(FieldPath.documentID(), in: joinedEventIds).getDocuments { snapshot, error in
                        if let snapshot = snapshot {
                            self.joinedEvents = snapshot.documents.compactMap { doc in
                                try? doc.data(as: Event.self)
                            }
                        } else if let error = error {
                            print("Error fetching joined events: \(error.localizedDescription)")
                            self.errorMessage = "Error fetching joined events."
                        }
                        dispatchGroup.leave()
                    }
                }

                if !organizedEventIds.isEmpty {
                    dispatchGroup.enter()
                    db.collection("events").whereField(FieldPath.documentID(), in: organizedEventIds).getDocuments { snapshot, error in
                        if let snapshot = snapshot {
                            self.organizedEvents = snapshot.documents.compactMap { doc in
                                try? doc.data(as: Event.self)
                            }
                        } else if let error = error {
                            print("Error fetching organized events: \(error.localizedDescription)")
                            self.errorMessage = "Error fetching organized events."
                        }
                        dispatchGroup.leave()
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    self.allEvents = (self.joinedEvents + self.organizedEvents).unique(by: \.id)
                    self.applyFilter()
                    self.isLoading = false
                }

            } else {
                self.errorMessage = "User document not found."
                self.isLoading = false
                print("User document not found: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func applyFilter() {
        switch selectedFilter {
        case .all:
            filteredEvents = allEvents
        case .joined:
            filteredEvents = joinedEvents
        case .organized:
            filteredEvents = organizedEvents
        }
    }
}

// Helper extension to filter unique events
extension Array where Element: Identifiable {
    func unique<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}

// Assuming Event model is Decodable and Identifiable as defined in ProfileView.swift

#Preview {
    AllEventsView()
} 