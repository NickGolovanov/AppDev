import SwiftUI

struct EventReviewsView: View {
    let eventId: String
    @StateObject private var reviewService = ReviewService()
    @State private var reviews: [Review] = []
    @State private var ratingSummary = EventRatingSummary.empty
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isLoading {
                    ProgressView("Loading reviews...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Rating Summary
                    ratingSummarySection
                    
                    // Individual Reviews
                    reviewsSection
                }
            }
            .padding()
        }
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadReviews()
        }
    }
    
    private var ratingSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overall Rating")
                .font(.title2)
                .fontWeight(.bold)
            
            if ratingSummary.totalReviews > 0 {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(String(format: "%.1f", ratingSummary.averageOverallRating))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading) {
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= Int(ratingSummary.averageOverallRating.rounded()) ? "star.fill" : "star")
                                            .foregroundColor(.purple)
                                            .font(.caption)
                                    }
                                }
                                Text("\(ratingSummary.totalReviews) review\(ratingSummary.totalReviews == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // Detailed Ratings
                VStack(spacing: 12) {
                    ratingBreakdown("Music", rating: ratingSummary.averageMusicRating, icon: "music.note", color: .blue)
                    ratingBreakdown("Location", rating: ratingSummary.averageLocationRating, icon: "location.fill", color: .green)
                    ratingBreakdown("Vibe", rating: ratingSummary.averageVibeRating, icon: "heart.fill", color: .pink)
                }
            } else {
                Text("No reviews yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    private func ratingBreakdown(_ title: String, rating: Double, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= Int(rating.rounded()) ? "star.fill" : "star")
                        .foregroundColor(color)
                        .font(.caption)
                }
            }
            
            Text(String(format: "%.1f", rating))
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 30, alignment: .trailing)
        }
    }
    
    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !reviews.isEmpty {
                Text("Reviews")
                    .font(.title2)
                    .fontWeight(.bold)
                
                ForEach(reviews) { review in
                    ReviewCard(review: review)
                }
            }
        }
    }
    
    private func loadReviews() async {
        do {
            async let reviewsTask = reviewService.fetchReviews(for: eventId)
            async let summaryTask = reviewService.getEventRatingSummary(eventId: eventId)
            
            reviews = try await reviewsTask
            ratingSummary = try await summaryTask
            isLoading = false
        } catch {
            print("Error loading reviews: \(error)")
            isLoading = false
        }
    }
}

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info and Overall Rating
            HStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(review.userName.prefix(1)).uppercased())
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.userName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(review.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= Int(review.overallRating) ? "star.fill" : "star")
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                }
            }
            
            // Detailed Ratings
            HStack(spacing: 16) {
                ratingPill("Music", rating: review.musicRating, color: .blue)
                ratingPill("Location", rating: review.locationRating, color: .green)
                ratingPill("Vibe", rating: review.vibeRating, color: .pink)
            }
            
            // Comment
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func ratingPill(_ title: String, rating: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
            Text(String(format: "%.0f", rating))
                .font(.caption2)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        EventReviewsView(eventId: "sample-event-id")
    }
}