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

    enum EventFilter: CaseIterable {
        case all
        case joined
        case organized
        
        var displayName: String {
            switch self {
            case .all: return "All"
            case .joined: return "Joined"
            case .organized: return "Organized"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(EventFilter.allCases, id: \.self) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .onChange(of: selectedFilter) { _ in
                applyFilter()
            }

            // Content
            if isLoading {
                ProgressView("Loading events...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        fetchAllEvents()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredEvents.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No events found for \(selectedFilter.displayName.lowercased()) filter.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredEvents) { event in
                    NavigationLink(destination: EventView(eventId: event.id ?? "")) {
                        EventRow(event: event)
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .listStyle(.plain)
                .refreshable {
                    await refreshEvents()
                }
            }
        }
        .navigationTitle("My Events")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if allEvents.isEmpty {
                fetchAllEvents()
            }
        }
    }

    // Helper view for displaying an event row in the list
    struct EventRow: View {
        let event: Event
        @AppStorage("userId") var userId: String = ""
        @StateObject private var reviewService = ReviewService()
        @State private var canReview = false
        @State private var hasReviewed = false
        @State private var showCreateReview = false
        @State private var isCheckingReviewStatus = false

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Event Image
                    AsyncImage(url: URL(string: event.imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "calendar")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .clipped()

                    // Event Details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(event.formattedDate)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(event.formattedTime)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Rating display
                        if let rating = event.averageRating, rating > 0 {
                            HStack(spacing: 4) {
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= Int(rating.rounded()) ? "star.fill" : "star")
                                            .foregroundColor(.purple)
                                            .font(.caption)
                                    }
                                }
                                Text("(\(event.totalReviews ?? 0))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Event Status
                        if event.hasEnded {
                            Text("Event Ended")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                }
                
                // Review button for ended events
                if event.hasEnded && canReview && !hasReviewed && !isCheckingReviewStatus {
                    Button(action: {
                        showCreateReview = true
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Write Review")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                if isCheckingReviewStatus {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Checking review status...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .task {
                await checkReviewStatus()
            }
            .sheet(isPresented: $showCreateReview) {
                CreateReviewView(event: event)
            }
        }
        
        private func checkReviewStatus() async {
            guard let eventId = event.id, !eventId.isEmpty, event.hasEnded, !userId.isEmpty else { 
                return 
            }
            
            isCheckingReviewStatus = true
            
            do {
                hasReviewed = try await reviewService.checkIfUserReviewed(eventId: eventId, userId: userId)
                canReview = !hasReviewed
            } catch {
                print("Error checking review status: \(error.localizedDescription)")
                canReview = false
            }
            
            isCheckingReviewStatus = false
        }
    }

    func fetchAllEvents() {
        guard !userId.isEmpty else {
            errorMessage = "User not logged in"
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        userRef.getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to fetch user data: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let document = document, document.exists else {
                    self.errorMessage = "User document not found"
                    self.isLoading = false
                    return
                }
                
                let data = document.data()
                let joinedEventIds = data?["joinedEventIds"] as? [String] ?? []
                let organizedEventIds = data?["organizedEventIds"] as? [String] ?? []
                
                // If no events, finish loading
                if joinedEventIds.isEmpty && organizedEventIds.isEmpty {
                    self.joinedEvents = []
                    self.organizedEvents = []
                    self.allEvents = []
                    self.applyFilter()
                    self.isLoading = false
                    return
                }

                let dispatchGroup = DispatchGroup()
                var fetchErrors: [String] = []

                // Fetch joined events
                if !joinedEventIds.isEmpty {
                    dispatchGroup.enter()
                    self.fetchEvents(withIds: joinedEventIds, db: db) { events, error in
                        if let events = events {
                            self.joinedEvents = events
                        } else if let error = error {
                            fetchErrors.append("Joined events: \(error)")
                        }
                        dispatchGroup.leave()
                    }
                }

                // Fetch organized events
                if !organizedEventIds.isEmpty {
                    dispatchGroup.enter()
                    self.fetchEvents(withIds: organizedEventIds, db: db) { events, error in
                        if let events = events {
                            self.organizedEvents = events
                        } else if let error = error {
                            fetchErrors.append("Organized events: \(error)")
                        }
                        dispatchGroup.leave()
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    if !fetchErrors.isEmpty {
                        self.errorMessage = "Errors occurred:\n" + fetchErrors.joined(separator: "\n")
                    }
                    
                    self.allEvents = (self.joinedEvents + self.organizedEvents).unique(by: \.id)
                    self.applyFilter()
                    self.isLoading = false
                }
            }
        }
    }
    
    private func fetchEvents(withIds ids: [String], db: Firestore, completion: @escaping ([Event]?, String?) -> Void) {
        // Firebase has a limit of 10 items for 'in' queries, so we need to batch them
        let batchSize = 10
        let batches = ids.chunked(into: batchSize)
        var allEvents: [Event] = []
        let dispatchGroup = DispatchGroup()
        var batchErrors: [String] = []
        
        for batch in batches {
            dispatchGroup.enter()
            db.collection("events")
                .whereField(FieldPath.documentID(), in: batch)
                .getDocuments { snapshot, error in
                    if let error = error {
                        batchErrors.append(error.localizedDescription)
                    } else if let snapshot = snapshot {
                        let events = snapshot.documents.compactMap { doc -> Event? in
                            do {
                                return try doc.data(as: Event.self)
                            } catch {
                                print("Error decoding event \(doc.documentID): \(error)")
                                return nil
                            }
                        }
                        allEvents.append(contentsOf: events)
                    }
                    dispatchGroup.leave()
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            if !batchErrors.isEmpty {
                completion(nil, batchErrors.joined(separator: ", "))
            } else {
                completion(allEvents, nil)
            }
        }
    }
    
    @MainActor
    private func refreshEvents() async {
        fetchAllEvents()
    }

    func applyFilter() {
        switch selectedFilter {
        case .all:
            filteredEvents = allEvents.sorted { $0.date > $1.date }
        case .joined:
            filteredEvents = joinedEvents.sorted { $0.date > $1.date }
        case .organized:
            filteredEvents = organizedEvents.sorted { $0.date > $1.date }
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

// Helper extension to chunk arrays
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    NavigationStack {
        AllEventsView()
    }
}
