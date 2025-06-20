import SwiftUI
import FirebaseFirestore

struct EventView: View {
    let eventId: String
    @State private var event: Event? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showGetTicket = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var hasJoinedEvent: Bool = false
    @Environment(\.dismiss) private var dismiss

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
                                Button(action: {
                                    dismiss()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                Spacer()
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
                                HStack(alignment: .center, spacing: 8) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.purple)
                                        .font(.system(size: 16))
                                    Text("\(event.formattedDate) · \(event.formattedTime)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                HStack(alignment: .center, spacing: 8) {
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
                            if hasJoinedEvent {
                                Text("You've already joined")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray)
                                    .cornerRadius(12)
                                    .padding(.top, 8)
                            } else {
                                let getTicketDestination = getTicketDestination
                                NavigationLink(destination: getTicketDestination, isActive: $showGetTicket) {
                                    EmptyView()
                                }
                                Button(action: {
                                    showGetTicket = true
                                }) {
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
        .navigationTitle(event?.title ?? "Event")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: fetchEvent)
        .navigationBarHidden(true)
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
            guard let document = snapshot, document.exists else {
                errorMessage = "Event not found."
                return
            }
            self.event = try? document.data(as: Event.self)
            if self.event != nil {
                checkIfUserJoinedEvent()
            } else {
                errorMessage = "Failed to decode event."
            }
        }
    }

    func checkIfUserJoinedEvent() {
        guard let userId = authViewModel.currentUser?.id else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, _ in
            if let document = document, document.exists {
                if let joinedEventIds = document.data()?["joinedEventIds"] as? [String] {
                    DispatchQueue.main.async {
                        self.hasJoinedEvent = joinedEventIds.contains(self.eventId)
                    }
                }
            }
        }
    }

    var getTicketDestination: some View {
        if let event = event {
            return AnyView(GetTicketView(event: event))
        } else {
            return AnyView(EmptyView())
        }
    }
}

#Preview {
    EventView(eventId: "someEventId")
        .environmentObject(AuthViewModel())
}
