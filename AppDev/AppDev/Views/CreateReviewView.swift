import SwiftUI

struct CreateReviewView: View {
    let event: Event
    @AppStorage("userId") var userId: String = ""
    @AppStorage("userName") var userName: String = ""
    @Environment(\.dismiss) private var dismiss
    
    @State private var overallRating: Double = 0
    @State private var musicRating: Double = 0
    @State private var locationRating: Double = 0
    @State private var vibeRating: Double = 0
    @State private var comment: String = ""
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @StateObject private var reviewService = ReviewService()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Event Info Header
                    eventHeaderSection
                    
                    // Rating Sections
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Rate Your Experience")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ratingSection(
                            title: "Overall Experience",
                            rating: $overallRating,
                            icon: "star.fill",
                            color: .purple
                        )
                        
                        ratingSection(
                            title: "Music & Entertainment",
                            rating: $musicRating,
                            icon: "music.note",
                            color: .blue
                        )
                        
                        ratingSection(
                            title: "Location & Venue",
                            rating: $locationRating,
                            icon: "location.fill",
                            color: .green
                        )
                        
                        ratingSection(
                            title: "Vibe & Atmosphere",
                            rating: $vibeRating,
                            icon: "heart.fill",
                            color: .pink
                        )
                    }
                    
                    // Comment Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Leave a Comment")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextEditor(text: $comment)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Submit Button
                    Button(action: submitReview) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        } else {
                            Text("Submit Review")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isFormValid ? Color.purple : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
                .padding()
            }
            .navigationTitle("Write Review")
            .navigationBarTitleDisplayMode(.large)
            .alert("Review Submission", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var eventHeaderSection: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: event.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 80, height: 80)
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                Text(event.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(event.location)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func ratingSection(title: String, rating: Binding<Double>, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= Int(rating.wrappedValue) ? "star.fill" : "star")
                        .foregroundColor(star <= Int(rating.wrappedValue) ? color : Color.gray.opacity(0.3))
                        .font(.title2)
                        .onTapGesture {
                            rating.wrappedValue = Double(star)
                        }
                }
                
                Text("(\(Int(rating.wrappedValue))/5)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    private var isFormValid: Bool {
        overallRating > 0 && musicRating > 0 && locationRating > 0 && vibeRating > 0
    }
    
    private func submitReview() {
        guard let eventId = event.id else { return }
        
        isSubmitting = true
        
        let review = Review(
            eventId: eventId,
            userId: userId,
            userName: userName.isEmpty ? "Anonymous" : userName,
            userProfileImageUrl: nil,
            overallRating: overallRating,
            musicRating: musicRating,
            locationRating: locationRating,
            vibeRating: vibeRating,
            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date()
        )
        
        Task {
            do {
                try await reviewService.submitReview(review)
                
                await MainActor.run {
                    isSubmitting = false
                    alertMessage = "Review submitted successfully!"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    alertMessage = "Failed to submit review: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}