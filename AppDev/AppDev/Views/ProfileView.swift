//
//  ContentView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var showEditProfile = false
    @State private var showQRCodeScanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HeaderView() // From develop branch
                    profileInfoSection
                    editAndScanButtons
                    statsSection
                    recentEventsSection
                }
                .padding()
                .navigationDestination(isPresented: $showEditProfile) {
                    EditProfileView()
                }
                .navigationDestination(isPresented: $showQRCodeScanner) {
                    QRCodeScannerView()
                }
            }
        }
    }

    var profileInfoSection: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Image("profile_placeholder")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 5)

                Circle()
                    .fill(Color(hex: "#7131C5"))
                    .frame(width: 28, height: 28)
                    .overlay(Image(systemName: "camera.fill").foregroundColor(.white))
                    .offset(x: 5, y: 5)
            }

            Text("Sarah Johnson")
                .font(.title2)
                .fontWeight(.bold)

            Text("@sarahj2025")
                .foregroundColor(.gray)

            Text("Psychology student at UvA. Love dancing and meeting new people! 🎓🕺")
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
                showQRCodeScanner = true
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
            statBox(title: "24", subtitle: "Events Joined")
            statBox(title: "8", subtitle: "Organized")
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
                Button(action: {}) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#7131C5"))
                }
            }

            VStack(spacing: 12) {
                eventCard(title: "Summer Beach Party", date: "Jun 15, 2025", icon: "music.note", badge: "Joined", badgeColor: Color.green.opacity(0.2))
                eventCard(title: "Club Night Special", date: "Jun 10, 2025", icon: "martini", badge: "Organized", badgeColor: Color.blue.opacity(0.2))
            }
        }
    }

    func eventCard(title: String, date: String, icon: String, badge: String, badgeColor: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#E9DDFD"))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "#7131C5"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(date)
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
}

#Preview {
    ProfileView()
}