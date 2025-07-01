import FirebaseFirestore
import Foundation
import MapKit

class HomeViewModel: ObservableObject {
    @Published var upcomingEvents: [Event] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func fetchEvents() {
        isLoading = true
        errorMessage = nil
        let db = Firestore.firestore()
        db.collection("events")
            .order(by: "createdAt", descending: true)
            .limit(to: 5)
            .getDocuments(completion: { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = "Failed to load events: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.errorMessage = "No events found."
                        return
                    }
                    
                    self?.upcomingEvents = documents.compactMap { doc in
                        let data = doc.data()
                        let id = doc.documentID
                        
                        guard let title = data["title"] as? String,
                              let date = data["date"] as? String,
                              let endTime = data["endTime"] as? String,
                              let startTime = data["startTime"] as? String,
                              let location = data["location"] as? String,
                              let imageUrl = data["imageUrl"] as? String,
                              let attendees = data["attendees"] as? Int,
                              let category = data["category"] as? String,
                              let price = data["price"] as? Double,
                              let maxCapacity = data["maxCapacity"] as? Int,
                              let description = data["description"] as? String
                        else {
                            return nil
                        }
                        
                        let latitude = data["latitude"] as? Double
                        let longitude = data["longitude"] as? Double
                        let averageRating = data["averageRating"] as? Double
                        let totalReviews = data["totalReviews"] as? Int
                        
                        return Event(
                            id: id,
                            title: title,
                            date: date,
                            endTime: endTime,
                            startTime: startTime,
                            location: location,
                            imageUrl: imageUrl,
                            attendees: attendees,
                            category: category,
                            price: price,
                            maxCapacity: maxCapacity,
                            description: description,
                            latitude: latitude,
                            longitude: longitude,
                            averageRating: averageRating,
                            totalReviews: totalReviews
                        )
                    }
                }
            })
    }
}