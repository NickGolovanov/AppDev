import SwiftUI
import FirebaseFirestore

struct EventView: View {
    let eventId: String
    @State private var event: EventDetails? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
                .padding(.horizontal)
                .padding(.bottom, 8)

            if isLoading {
                ProgressView().padding()
            } else if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red).padding()
            } else if let event = event {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ZStack(alignment: .topLeading) {
                            // Event Image
                            if let imageUrl = URL(string: event.imageUrl) {
                                AsyncImage(url: imageUrl) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                        .frame(height: 240)
                                    .clipped()
                            } placeholder: {
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(height: 240)
                                }
                            } else {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.5)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(height: 240)
                            }
                            
                            // Back and Favorite buttons
                            HStack {
                                Button(action: {}) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                Spacer()
                                Button(action: {}) {
                                    Image(systemName: "heart")
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }

                        // Event Card
                        VStack(alignment: .leading, spacing: 24) {
                            // Title
                            Text(event.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.top, 8)

                            // Date, Time, Location
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.purple)
                                        .font(.system(size: 16))
                                    Text("event.formattedDate · event.formattedTime")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.purple)
                                        .font(.system(size: 16))
                                    Text(event.location)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }

                            // About Event
                            VStack(alignment: .leading, spacing: 12) {
                                Text("About Event")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(event.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineSpacing(4)
                            }

                            // People Attending
                            VStack(alignment: .leading, spacing: 12) {
                                Text("People Attending")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                HStack(spacing: 8) {
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(.purple)
                                        .font(.system(size: 16))
                                Text("\(event.attendees) going")
                                    .font(.subheadline)
                                    .foregroundColor(.purple)
                                }
                            }

                            // Price and Tickets
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Price per ticket")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("€\(String(format: "%.2f", event.price))")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Available tickets")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(event.maxCapacity - event.attendees) left")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                            // Get Ticket Button
                            Button(action: {}) {
                                Text("Get Ticket Now")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                            }
                            .padding(.top, 8)
                            .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color(.systemGray4), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 8)
                        .offset(y: -40)
                    }
                }
                .background(Color(.systemGray6).ignoresSafeArea())
            }
        }
        .onAppear(perform: fetchEvent)
    }

    func fetchEvent() {
        isLoading = true
        errorMessage = nil
        let db = Firestore.firestore()
        db.collection("events").document(eventId).getDocument { snapshot, error in
            isLoading = false
            if let error = error {
                errorMessage = "Failed to load event: \(error.localizedDescription)"
                return
            }
            guard let data = snapshot?.data() else {
                errorMessage = "Event not found."
                return
            }
            // Map Firestore data to EventDetails
            guard let title = data["title"] as? String,
                  let date = data["date"] as? String,
                  let startTime = data["startTime"] as? String,
                  let location = data["location"] as? String,
                  let imageUrl = data["imageUrl"] as? String,
                  let attendees = data["attendees"] as? Int,
                  let maxCapacity = data["maxCapacity"] as? Int,
                  let price = data["price"] as? Double,
                  let description = data["description"] as? String else {
                errorMessage = "Event data is incomplete."
                return
            }
            self.event = EventDetails(title: title, date: date, startTime: startTime, location: location, imageUrl: imageUrl, attendees: attendees, maxCapacity: maxCapacity, price: price, description: description)
        }
    }
}

struct EventDetails {
    let title: String
    let date: String
    let startTime: String
    let location: String
    let imageUrl: String
    let attendees: Int
    let maxCapacity: Int
    let price: Double
    let description: String
}

#Preview {
    EventView(eventId: "someEventId")
}
