import SwiftUI
import FirebaseFirestore

struct RatingView: View {
    let eventId: String
    let eventTitle: String
    @AppStorage("userId") var userId: String = ""
    
    @State private var musicRating: Int = 0
    @State private var locationRating: Int = 0
    @State private var vibeRating: Int = 0
    @State private var comment: String = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Rate Your Experience")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Help improve future events by rating different aspects of \(eventTitle)")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 20) {
                        RatingSection(
                            title: "Music",
                            icon: "music.note",
                            rating: $musicRating
                        )
                        
                        RatingSection(
                            title: "Location",
                            icon: "location",
                            rating: $locationRating
                        )
                        
                        RatingSection(
                            title: "Vibe",
                            icon: "heart",
                            rating: $vibeRating
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Comments (Optional)")
                            .font(.headline)
                        
                        TextEditor(text: $comment)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    Button(action: submitRating) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Submit Rating")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(allRatingsProvided ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(!allRatingsProvided || isSubmitting)
                }
                .padding()
            }
            .navigationTitle("Rate Event")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Rating Submitted!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for your feedback!")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private var allRatingsProvided: Bool {
        musicRating > 0 && locationRating > 0 && vibeRating > 0
    }
    
    private func submitRating() {
        isSubmitting = true
        
        let rating = Rating(
            eventId: eventId,
            userId: userId,
            musicRating: musicRating,
            locationRating: locationRating,
            vibeRating: vibeRating,
            comment: comment.isEmpty ? nil : comment,
            timestamp: Date()
        )
        
        let db = Firestore.firestore()
        
        do {
            try db.collection("ratings").addDocument(from: rating) { error in
                DispatchQueue.main.async {
                    isSubmitting = false
                    if let error = error {
                        errorMessage = "Failed to submit rating: \(error.localizedDescription)"
                    } else {
                        showSuccessAlert = true
                    }
                }
            }
        } catch {
            isSubmitting = false
            errorMessage = "Failed to submit rating: \(error.localizedDescription)"
        }
    }
}

struct RatingSection: View {
    let title: String
    let icon: String
    @Binding var rating: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Button(action: {
                        rating = star
                    }) {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(star <= rating ? .yellow : .gray)
                            .font(.title2)
                    }
                }
                
                if rating > 0 {
                    Text(ratingDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var ratingDescription: String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }
}