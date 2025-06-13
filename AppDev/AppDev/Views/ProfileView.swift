//
//  ContentView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

import FirebaseFirestore
import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @AppStorage("userId") var userId: String = ""
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
            ScrollView {
                VStack(spacing: 16) {
                    HeaderView()
                    profileInfoSection
                    editAndScanButtons
                    statsSection
                    recentEventsSection
                }
                .padding()
                .navigationDestination(isPresented: $showEditProfile) {
                    EditProfileView()
                }
                .navigationDestination(isPresented: $showOrganizedEventsForScan) {
                    OrganizedEventsForScanView()
                }
                .navigationDestination(isPresented: $showAllEvents) {
                    AllEventsView()
                }
            }
        }
        .onAppear(perform: fetchRecentEvents)
    }

    var profileInfoSection: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                if !userProfileImageURL.isEmpty, let url = URL(string: userProfileImageURL) {
                    AsyncImage(url: url) {
                        image in
                        image.resizable()
                    } placeholder: {
                        Image("profile_placeholder")  // Keep placeholder for loading/error
                            .resizable()
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 5)
                } else {
                    Circle()
                        .fill(Color(hex: "#7131C5"))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(userName.prefix(1)).uppercased())
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                }

                Circle()
                    .fill(Color(hex: "#7131C5"))
                    .frame(width: 28, height: 28)
                    .overlay(Image(systemName: "camera.fill").foregroundColor(.white))
                    .offset(x: 5, y: 5)
            }

            Text(userName)
                .font(.title2)
                .fontWeight(.bold)

            Text(userHandle)
                .foregroundColor(.gray)

            Text(userBio)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.top)
    }

    var editAndScanButtons: some View {
        HStack(spacing: 20) {
            Button(action: {
                showEditProfile = true
            }) {
                Text("Edit Profile")
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "#7131C5"))
                    .padding(.vertical, 8)
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
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#7131C5"), lineWidth: 1.5)
                    )
            }
        }
        .padding(.top, 12)
    }

    var statsSection: some View {
        HStack(spacing: 16) {
            statBox(title: "\(joinedEvents.count)", subtitle: "Events Joined")
            statBox(title: "\(organizedEvents.count)", subtitle: "Organized")
            statBox(title: "156", subtitle: "Connections")
        }
    }

    func statBox(title: String, subtitle: String) -> some View {
        VStack {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#7131C5"))
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    var recentEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Events")
                    .font(.headline)
                Spacer()
                Button(action: { showAllEvents = true }) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#7131C5"))
                }
            }

            VStack(spacing: 12) {
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
                    Text("No recent events.")
                        .foregroundColor(.gray)
                }
            }

            // Logout Button
            Button(action: logout) {
                Text("Logout")
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red, lineWidth: 1.5)
                    )
            }
            .padding(.top, 20)
        }
    }

    func eventCard(event: Event, badge: String, badgeColor: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#E9DDFD"))
                    .frame(width: 40, height: 40)

                if let imageUrl = URL(string: event.imageUrl), !event.imageUrl.isEmpty {
                    AsyncImage(url: imageUrl) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                    } placeholder: {
                        Image(systemName: "calendar")
                            .foregroundColor(Color(hex: "#7131C5"))
                    }
                } else {
                    Image(systemName: "calendar")
                        .foregroundColor(Color(hex: "#7131C5"))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("\(event.formattedDate), \(event.formattedTime)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(badge)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(badgeColor)
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    func fetchRecentEvents() {
        guard !userId.isEmpty else { return }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        userRef.getDocument { document, error in
            guard let document = document, document.exists, let data = document.data() else {
                print("User document not found: \(error?.localizedDescription ?? "Unknown error")")
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
        do {
            try Auth.auth().signOut()
            userId = "" // Clear the userId from AppStorage
            // Navigate to login or initial view
            // This typically handled by observing auth state in AppDevApp.swift or similar
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}


#Preview {
    ProfileView()
}
