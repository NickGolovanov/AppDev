import Foundation
import FirebaseFirestore
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
            .getDocuments { [weak self] snapshot, error in
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
                              let location = data["location"] as? String,
                              let imageUrl = data["imageUrl"] as? String,
                              let attendees = data["attendees"] as? Int,
                              let category = data["category"] as? String,
                              let price = data["price"] as? Double else {
                            return nil
                        }
                        return Event(
                            id: id,
                            title: title,
                            date: date,
                            location: location,
                            coordinate: nil,
                            imageUrl: imageUrl,
                            attendees: attendees,
                            distance: nil,
                            category: category,
                            price: price
                        )
                    }
                }
            }
    }
} 