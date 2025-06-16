//
//  HeaderView.swift
//  AppDev
//
//  Created by Viktor Harhat on 12/05/2025.
//

import SwiftUI

struct HeaderView: View {
    var title: String?
    var showProfileLink: Bool = true
    
    @State private var isProfileViewActive: Bool = false

    var body: some View {
        HStack {
            if let title = title {
                Text(title)
                    .font(.headline)
            } else {
                Text("PartyPal")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            if title == nil && showProfileLink {
                Button(action: {
                    if !isProfileViewActive {
                        isProfileViewActive = true
                    }
                }) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.largeTitle)
                        .padding(.leading, 10)
                }
                .background(
                    NavigationLink(
                        destination: ProfileView(),
                        isActive: $isProfileViewActive
                    ) {
                        EmptyView()
                    }
                )
            }
        }
        .padding(2)
    }
}

#Preview {
    VStack {
        HeaderView()
        HeaderView(title: "Chat")
        HeaderView(title: "Get Ticket", showProfileLink: false)
    }
}
