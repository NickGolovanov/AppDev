struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User Info and Overall Rating
            HStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("A") // Anonymous - don't show actual name initial
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Anonymous Reviewer") // Keep it anonymous
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(review.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(review.overallRating) ? "star.fill" : "star")
                                .foregroundColor(.purple)
                                .font(.caption)
                        }
                    }
                    Text("Overall Rating")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Detailed Ratings
            HStack(spacing: 16) {
                ratingPill("Music", rating: review.musicRating, color: .blue)
                ratingPill("Location", rating: review.locationRating, color: .green)
                ratingPill("Vibe", rating: review.vibeRating, color: .pink)
            }
            
            // Comment Section - ALWAYS show, make it prominent
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
                
                Group {
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
                    } else {
                        Text("No written feedback provided")
                            .font(.body)
                            .foregroundColor(.gray)
                            .italic()
                            .padding(12)
                            .background(Color(.systemGray6).opacity(0.5))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}