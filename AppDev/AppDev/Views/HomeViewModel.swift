import Foundation
import FirebaseFirestore

struct HomeEvent: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let tags: [String]
    let imageName: String
    let bgColor: String
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
                    subtitle: data["subtitle"] as? String ?? "",
                    tags: data["tags"] as? [String] ?? [],
                    imageName: data["imageName"] as? String ?? "",
                    bgColor: data["bgColor"] as? String ?? "gray"
                )
            }
        }
    }
}