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
                    // Quick Summary Component
                    QuickReviewsSummaryComponent(ratingSummary: ratingSummary)
                    
                    // Detailed Rating Summary
                    ratingSummarySection
                    
                    // Individual Reviews
                    reviewsSection
                }
            }
            .padding()
        }
        .navigationTitle("Reviews & Feedback")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadReviews()
        }
    }
    
    private var ratingSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Ratings")
                .font(.title2)
                .fontWeight(.bold)
            
            if ratingSummary.totalReviews > 0 {
                // Detailed Ratings Breakdown
                VStack(spacing: 12) {
                    ratingBreakdown("Music Quality", rating: ratingSummary.averageMusicRating, icon: "music.note", color: .blue)
                    ratingBreakdown("Location", rating: ratingSummary.averageLocationRating, icon: "location.fill", color: .green)
                    ratingBreakdown("Atmosphere & Vibe", rating: ratingSummary.averageVibeRating, icon: "heart.fill", color: .pink)
                }
            } else {
                Text("No detailed ratings available yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(12)
    }
    
    private func ratingBreakdown(_ title: String, rating: Double, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
                .font(.system(size: 16))
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= Int(rating.rounded()) ? "star.fill" : "star")
                        .foregroundColor(color)
                        .font(.caption)
                }
            }
            
            Text(String(format: "%.1f", rating))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .frame(width: 35, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !reviews.isEmpty {
                HStack {
                    Text("Participant Feedback")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(reviews.count) review\(reviews.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(6)
                }
                
                ForEach(reviews.sorted(by: { $0.createdAt > $1.createdAt })) { review in
                    EnhancedReviewCard(review: review)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No reviews yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Reviews will appear here after participants rate the event")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .frame(maxWidth: .infinity)
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

// New: - Quick Reviews Summary Component
struct QuickReviewsSummaryComponent: View {
    let ratingSummary: EventRatingSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("Event Rating Summary")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            if ratingSummary.totalReviews > 0 {
                HStack(spacing: 20) {
                    // Overall Rating Circle
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(Color.purple.opacity(0.2), lineWidth: 8)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: ratingSummary.averageOverallRating / 5.0)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                            
                            VStack(spacing: 2) {
                                Text(String(format: "%.1f", ratingSummary.averageOverallRating))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                                
                                HStack(spacing: 1) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= Int(ratingSummary.averageOverallRating.rounded()) ? "star.fill" : "star")
                                            .foregroundColor(.purple)
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        
                        Text("Overall")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                    }
                    
                    // Stats Grid
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            StatItem(
                                title: "Music",
                                value: String(format: "%.1f", ratingSummary.averageMusicRating),
                                color: .blue,
                                icon: "music.note"
                            )
                            
                            StatItem(
                                title: "Location",
                                value: String(format: "%.1f", ratingSummary.averageLocationRating),
                                color: .green,
                                icon: "location.fill"
                            )
                        }
                        
                        HStack(spacing: 16) {
                            StatItem(
                                title: "Vibe",
                                value: String(format: "%.1f", ratingSummary.averageVibeRating),
                                color: .pink,
                                icon: "heart.fill"
                            )
                            
                            StatItem(
                                title: "Reviews",
                                value: "\(ratingSummary.totalReviews)",
                                color: .purple,
                                icon: "bubble.left.and.bubble.right"
                            )
                        }
                    }
                    
                    Spacer()
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No ratings yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Participants can rate the event after attending")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "star.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.3))
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
}

// New: - Stat Item Component
struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// New: - Enhanced Review Card
struct EnhancedReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User Info and Overall Rating
            HStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("A") // Anonymous
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Anonymous Reviewer")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(review.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(review.overallRating) ? "star.fill" : "star")
                                .foregroundColor(.purple)
                                .font(.caption)
                        }
                    }
                    Text("Overall: \(String(format: "%.1f", review.overallRating))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Detailed Ratings
            HStack(spacing: 12) {
                ratingPill("Music", rating: review.musicRating, color: .blue)
                ratingPill("Location", rating: review.locationRating, color: .green)
                ratingPill("Vibe", rating: review.vibeRating, color: .pink)
            }
            
            // Comment Section - ALWAYS VISIBLE
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "quote.bubble.fill")
                        .foregroundColor(.purple)
                        .font(.subheadline)
                    Text("Participant Feedback")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    Spacer()
                }
                
                if !review.comment.isEmpty {
                    Text("\"\(review.comment)\"")
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundColor(.gray.opacity(0.5))
                            .font(.caption)
                        Text("No written feedback provided")
                            .font(.body)
                            .foregroundColor(.gray)
                            .italic()
                    }
                    .padding(12)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func ratingPill(_ title: String, rating: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            Text(String(format: "%.0f", rating))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

// Legacy ReviewCard for backward compatibility
struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        EnhancedReviewCard(review: review)
    }
}

#Preview {
    NavigationView {
        EventReviewsView(eventId: "sample-event-id")
    }
}