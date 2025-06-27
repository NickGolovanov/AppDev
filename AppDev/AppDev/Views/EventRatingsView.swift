import SwiftUI
import FirebaseFirestore

struct EventRatingsView: View {
    let eventId: String
    let eventTitle: String
    
    @State private var ratings: [Rating] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView()
                } else if ratings.isEmpty {
                    Text("No ratings yet")
                        .foregroundColor(.secondary)
                } else {
                    RatingSummaryView(ratings: ratings)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(ratings) { rating in
                            RatingCardView(rating: rating)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Event Ratings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchRatings()
        }
    }
    
    private func fetchRatings() {
        let db = Firestore.firestore()
        
        db.collection("ratings")
            .whereField("eventId", isEqualTo: eventId)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        errorMessage = error.localizedDescription
                        return
                    }
                    
                    ratings = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: Rating.self)
                    } ?? []
                }
            }
    }
}

struct RatingSummaryView: View {
    let ratings: [Rating]
    
    var averageMusic: Double {
        Double(ratings.map(\.musicRating).reduce(0, +)) / Double(ratings.count)
    }
    
    var averageLocation: Double {
        Double(ratings.map(\.locationRating).reduce(0, +)) / Double(ratings.count)
    }
    
    var averageVibe: Double {
        Double(ratings.map(\.vibeRating).reduce(0, +)) / Double(ratings.count)
    }
    
    var overallAverage: Double {
        (averageMusic + averageLocation + averageVibe) / 3.0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Overall Rating")
                .font(.headline)
            
            HStack {
                Text(String(format: "%.1f", overallAverage))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: Double(star) <= overallAverage ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                    }
                    Text("(\(ratings.count) reviews)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 20) {
                RatingBreakdownItem(title: "Music", rating: averageMusic, icon: "music.note")
                RatingBreakdownItem(title: "Location", rating: averageLocation, icon: "location")
                RatingBreakdownItem(title: "Vibe", rating: averageVibe, icon: "heart")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RatingBreakdownItem: View {
    let title: String
    let rating: Double
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.1f", rating))
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

struct RatingCardView: View {
    let rating: Rating
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Anonymous User")
                    .font(.headline)
                Spacer()
                Text(rating.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                RatingItemView(title: "Music", rating: rating.musicRating)
                RatingItemView(title: "Location", rating: rating.locationRating)
                RatingItemView(title: "Vibe", rating: rating.vibeRating)
            }
            
            if let comment = rating.comment, !comment.isEmpty {
                Text(comment)
                    .font(.body)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct RatingItemView: View {
    let title: String
    let rating: Int
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 1) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundColor(star <= rating ? .yellow : .gray)
                }
            }
        }
    }
}