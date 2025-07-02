import SwiftUI
import FirebaseAuth

struct TestRecommendationView: View {
    @StateObject private var recommendationService = RecommendationService()
    @StateObject private var testDataService = TestDataService()
    @State private var testResults: [String] = []
    @State private var isRunningTests = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Test Controls
                    VStack(spacing: 16) {
                        Text("Recommendation System Testing")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Button("Create Test Events") {
                            Task {
                                await testDataService.createTestEvents()
                                testResults.append("Created test events")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(testDataService.isCreatingTestData)
                        
                        Button("Simulate User Behavior") {
                            Task {
                                if let userId = Auth.auth().currentUser?.uid {
                                    await testDataService.simulateUserBehavior(userId: userId)
                                    testResults.append("Simulated user behavior")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(testDataService.isCreatingTestData)
                        
                        Button("Generate Recommendations") {
                            Task {
                                isRunningTests = true
                                await recommendationService.generateRecommendations()
                                testResults.append("Generated \(recommendationService.recommendedEvents.count) recommendations")
                                isRunningTests = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isRunningTests || recommendationService.isLoading)
                        
                        Button("Track Test Interaction") {
                            if let firstEvent = recommendationService.recommendedEvents.first {
                                recommendationService.trackUserAction(
                                    eventId: firstEvent.id ?? "test",
                                    actionType: .clicked,
                                    event: firstEvent
                                )
                                testResults.append("Tracked click on: \(firstEvent.title)")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(recommendationService.recommendedEvents.isEmpty)
                        
                        // Show current operation
                        if testDataService.isCreatingTestData {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(testDataService.lastOperation)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Test Results
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Test Results")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isRunningTests || recommendationService.isLoading {
                            ProgressView("Running tests...")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        ForEach(testResults, id: \.self) { result in
                            Text(result)
                                .font(.caption)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        if !testDataService.lastOperation.isEmpty && !testDataService.isCreatingTestData {
                            Text("Last operation: \(testDataService.lastOperation)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .italic()
                        }
                        
                        Button("Clear Results") {
                            testResults.removeAll()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    
                    // Recommended Events Display
                    if !recommendationService.recommendedEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommended Events")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(recommendationService.recommendedEvents) { event in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(event.title)
                                        .font(.headline)
                                    
                                    HStack {
                                        Text("Category: \(event.category)")
                                            .font(.caption)
                                            .padding(4)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(4)
                                        
                                        Text("Price: €\(String(format: "%.2f", event.price))")
                                            .font(.caption)
                                            .padding(4)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(4)
                                        
                                        if let rating = event.averageRating {
                                            Text("Rating: \(String(format: "%.1f", rating))")
                                                .font(.caption)
                                                .padding(4)
                                                .background(Color.orange.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                    
                                    Text(event.location)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .onTapGesture {
                                    // Track interaction when user taps on recommended event
                                    recommendationService.trackUserAction(
                                        eventId: event.id ?? "unknown",
                                        actionType: .clicked,
                                        event: event
                                    )
                                    testResults.append("Tracked recommendation click: \(event.title)")
                                }
                            }
                        }
                    }
                    
                    // Debug Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🔍 Debug Info")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("User ID: \(Auth.auth().currentUser?.uid ?? "Not logged in")")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("Recommendations loaded: \(recommendationService.isLoading ? "Loading..." : "Complete")")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let error = recommendationService.errorMessage {
                            Text("Error: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Test Recommendations")
        }
    }
}

#Preview {
    TestRecommendationView()
}