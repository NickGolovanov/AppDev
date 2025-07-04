import FirebaseFirestore
import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @State private var showOrganizedEventsForScan = false
    @State private var showAllEvents = false

    @State private var userName: String = "Loading..."
    @State private var userHandle: String = "@loading..."
    @State private var userBio: String = "Loading bio..."
    @State private var userProfileImageURL: String = ""

    @State private var joinedEvents: [Event] = []
    @State private var organizedEvents: [Event] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Fixed top section - made more compact
                VStack(spacing: 12) {
                    HeaderView(showProfileLink: false)
                    profileInfoSection
                    editAndScanButtons
                    statsSection
                }
                .padding()
                .background(Color.white)

                // Expanded scrollable events section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Events")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, 16)

                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(joinedEvents) { event in
                                NavigationLink(destination: EventView(eventId: event.id ?? "-1")) {
                                    eventCard(
                                        event: event, badge: "Joined", badgeColor: Color.green.opacity(0.2))
                                }
                            }

                            ForEach(organizedEvents) { event in
                                NavigationLink(destination: EventView(eventId: event.id ?? "-1")) {
                                    eventCard(
                                        event: event, badge: "Organized", badgeColor: Color.blue.opacity(0.2))
                                }
                            }

                            if joinedEvents.isEmpty && organizedEvents.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    
                                    Text("No recent events")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    
                                    Text("Join or organize events to see them here!")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20) // Extra padding at bottom
                    }
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.5) // Increased from 0.4 to 0.5
                }
                .background(Color(.systemGray6))

                Spacer(minLength: 20) // Minimum spacer

                // Fixed bottom section with logout button - moved closer to bottom
                VStack {
                    Button(action: logout) {
                        Text("Logout")
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 1.5)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16) // Reduced padding to move closer to bottom
                }
                .background(Color.white)
            }
            .navigationDestination(isPresented: $showEditProfile) {
                EditProfileView()
                    .onDisappear {
                        // Refresh profile data when returning from edit view
                        fetchRecentEvents()
                    }
            }
            .navigationDestination(isPresented: $showOrganizedEventsForScan) {
                OrganizedEventsForScanView()
            }
        }
        .onAppear(perform: fetchRecentEvents)
    }

    var profileInfoSection: some View {
        VStack(spacing: 6) { // Reduced spacing
            ZStack(alignment: .bottomTrailing) {
                if !userProfileImageURL.isEmpty, let url = URL(string: userProfileImageURL) {
                    AsyncImage(url: url) {
                        image in
                        image.resizable()
                    } placeholder: {
                        Image("profile_placeholder")  // Keep placeholder for loading/error
                            .resizable()
                    }
                    .frame(width: 90, height: 90) // Slightly smaller
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 5)
                } else {
                    Circle()
                        .fill(Color(hex: "#7131C5"))
                        .frame(width: 90, height: 90) // Slightly smaller
                        .overlay(
                            Text(String(userName.prefix(1)).uppercased())
                                .font(.system(size: 36, weight: .bold)) // Adjusted font size
                                .foregroundColor(.white)
                        )
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                }
            }

            Text(userName)
                .font(.title3) // Slightly smaller
                .fontWeight(.bold)

            Text(userHandle)
                .foregroundColor(.gray)
                .font(.subheadline)

            Text(userBio)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .lineLimit(3) // Limit bio lines
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    var editAndScanButtons: some View {
        HStack(spacing: 16) {
            Button(action: {
                showEditProfile = true
            }) {
                Text("Edit Profile")
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "#7131C5"))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#7131C5"), lineWidth: 1.5)
                    )
            }

            Button(action: {
                showOrganizedEventsForScan = true
            }) {
                Text("Scan QR Code")
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "#7131C5"))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#7131C5"), lineWidth: 1.5)
                    )
            }
        }
        .padding(.top, 8)
    }

    var statsSection: some View {
        HStack(spacing: 16) {
            statBox(title: "\(joinedEvents.count)", subtitle: "Events Joined")
            statBox(title: "\(organizedEvents.count)", subtitle: "Organized")
        }
    }

    func statBox(title: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.title2) // Slightly smaller
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#7131C5"))
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12) // Reduced padding
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    func eventCard(event: Event, badge: String, badgeColor: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#E9DDFD"))
                    .frame(width: 60, height: 60) // Larger image area

                if let imageUrl = URL(string: event.imageUrl), !event.imageUrl.isEmpty {
                    AsyncImage(url: imageUrl) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .cornerRadius(12)
                    } placeholder: {
                        Image(systemName: "calendar")
                            .foregroundColor(Color(hex: "#7131C5"))
                            .font(.title2)
                    }
                } else {
                    Image(systemName: "calendar")
                        .foregroundColor(Color(hex: "#7131C5"))
                        .font(.title2)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text("\(event.formattedDate), \(event.formattedTime)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(event.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(spacing: 4) {
                Text(badge)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(badgeColor)
                    .cornerRadius(8)
                
                if let rating = event.averageRating, rating > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                        Text(String(format: "%.1f", rating))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(16) // Increased padding
        .background(Color.white)
        .cornerRadius(16) // Larger corner radius
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3) // Enhanced shadow
    }

    func fetchRecentEvents() {
        guard let userId = authViewModel.currentUser?.id else {
            print("ProfileView: Current user ID is nil from AuthViewModel.")
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        userRef.getDocument { document, error in
            guard let document = document, document.exists, let data = document.data() else {
                print("User document not found: \(error?.localizedDescription ?? "Unknown error")")
                self.userName = "Not found"
                self.userHandle = "@notfound"
                self.userBio = "User profile not found."
                return
            }

            self.userName = data["fullName"] as? String ?? "N/A"
            self.userHandle = data["username"] as? String ?? "@n/a"
            self.userBio = data["description"] as? String ?? ""
            self.userProfileImageURL = data["profileImageUrl"] as? String ?? ""

            let joinedEventIds = data["joinedEventIds"] as? [String] ?? []
            let organizedEventIds = data["organizedEventIds"] as? [String] ?? []

            print(organizedEventIds)

            if !joinedEventIds.isEmpty {
                db.collection("events").whereField(FieldPath.documentID(), in: joinedEventIds)
                    .getDocuments { snapshot, error in
                        if let snapshot = snapshot {
                            self.joinedEvents = snapshot.documents.compactMap { doc in
                                try? doc.data(as: Event.self)
                            }
                        } else {
                            print(
                                "Error fetching joined events: \(error?.localizedDescription ?? "")"
                            )
                        }
                    }
            }

            if !organizedEventIds.isEmpty {
                db.collection("events").whereField(FieldPath.documentID(), in: organizedEventIds)
                    .getDocuments { snapshot, error in
                        if let snapshot = snapshot {
                            self.organizedEvents = snapshot.documents.compactMap { doc -> Event? in
                                do {
                                    let event = try doc.data(as: Event.self)
                                    return event
                                } catch {
                                    print(
                                        "Error decoding organized event with ID \(doc.documentID): \(error.localizedDescription)"
                                    )
                                    print("Raw data for event \(doc.documentID): \(doc.data())")
                                    return nil
                                }
                            }
                            print(
                                "self.organizedEvents after attempting decode: \(self.organizedEvents)"
                            )
                        } else {
                            print(
                                "Error fetching organized events: \(error?.localizedDescription ?? "")"
                            )
                        }
                    }
            }
        }
    }

    func logout() {
        authViewModel.signOut()
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}