//
//  ContentView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

import SwiftUI

struct ContentView: View {
    // State to track navigation to EditProfileView
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header Section
                    headerSection
                    
                    // Profile Info Section
                    profileInfoSection

                    // Edit Button
                    editProfileButton
                    
                    // Stats Section
                    statsSection
                    
                    // Recent Events Section
                    recentEventsSection
                    
                    // Footer Placeholder
                    footerPlaceholder
                }
                .padding()
                .navigationDestination(isPresented: $showEditProfile) {
                    EditProfileView()  // Navigate to EditProfileView when the button is pressed
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Section Extensions
extension ContentView {
    
    // MARK: Header
    var headerSection: some View {
        HStack {
            Text("PartyPal")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()
            
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.title2)
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .offset(x: 6, y: -6)
            }
            
            Image(systemName: "person.crop.circle.fill")
                .font(.largeTitle)
                .padding(.leading, 10)
        }
    }
    
    // MARK: Profile Info Section
    var profileInfoSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .clipShape(Circle())
                .shadow(radius: 4)

            Text("Nikita Golovanov")
                .font(.title2)
                .fontWeight(.semibold)

            Text("@nikitag")
                .font(.subheadline)
                .foregroundColor(.gray)

            Text("Lover of events, organizing chaos into memories. 🎉")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.top)
    }

    
    // MARK: Stats Section
    var statsSection: some View {
        HStack(spacing: 16) {
            VStack {
                Text("24")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Joined")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            VStack {
                Text("8")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Organized")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    
    var recentEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Events")
                    .font(.headline)
                Spacer()
                Button(action: {
                    // Future navigation
                }) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }

            VStack(spacing: 12) {
                EventCardView(title: "Summer Beach Party")
                EventCardView(title: "Startup Mixer")
                EventCardView(title: "New Year's Bash")
            }
        }
    }


    func eventCard(title: String) -> some View {
        Button(action: {
            // Future event navigation
        }) {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }

    

    var footerPlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(height: 60)
            .overlay(
                Text("Footer Placeholder")
                    .font(.footnote)
                    .foregroundColor(.gray)
            )
            .cornerRadius(12)
            .padding(.top, 10)
    }
    
    // MARK: Edit Profile Button
    var editProfileButton: some View {
        Button(action: {
            // Navigate to EditProfileView
            showEditProfile = true
        }) {
            Text("Edit Profile")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 1)
                )
        }
    }

}
