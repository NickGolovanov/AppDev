import Foundation

struct HomeEvent: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let tags: [String]
    let imageName: String
    let bgColor: String // Use string for color name
}


// Make mock data while waiting for Mihail's Event Page
class HomeViewModel: ObservableObject {
    @Published var trendingEvents: [HomeEvent] = [
        HomeEvent(title: "Neon Dreams", subtitle: "22:00 · Club Matrix", tags: ["House", "Hot"], imageName: "neodreams", bgColor: "purple"),
        HomeEvent(title: "Beach Blast", subtitle: "20:00 · Zandvoort", tags: ["Beach", "Chill"], imageName: "beach", bgColor: "pink")
    ]
    @Published var upcomingEvents: [HomeEvent] = [
        HomeEvent(title: "Amsterdam Student Night", subtitle: "May 5, 2025 · 21:00", tags: ["Smart Casual"], imageName: "amsterdam", bgColor: "blue"),
        HomeEvent(title: "TU Delft Spring Party", subtitle: "May 7, 2025 · 22:00", tags: ["Casual"], imageName: "delft", bgColor: "green")
    ]
    
    // Later, I add a fetch function here to get real data from Event page of Mihail.
}