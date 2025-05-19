import Foundation
import FirebaseFirestore

struct HomeEvent: Identifiable {
    let id: String
    let title: String
    let description: String
    let date: String
    let imageUrl: String
    let category: String
    let price: Int
}

class HomeViewModel: ObservableObject {
    @Published var upcomingEvents: [HomeEvent] = []

    func fetchEvents() {
        let db = Firestore.firestore()
        db.collection("Event").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching events: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            self.upcomingEvents = documents.compactMap { doc in
                let data = doc.data()
                return HomeEvent(
                    id: doc.documentID,
                    title: data["title"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    date: data["date"] as? String ?? "",
                    imageUrl: data["imageUrl"] as? String ?? "",
                    category: data["category"] as? String ?? "",
                    price: data["price"] as? Int ?? 0
                )
            }
            print("Fetched \(self.upcomingEvents.count) events")
        }
    }
}