//
//  HeaderView.swift
//  AppDev
//
//  Created by Viktor Harhat on 12/05/2025.
//

import SwiftUI

struct HeaderView: View {
    var title: String?
    var showBackButton: Bool = false
    
    var body: some View {
        HStack {
            if showBackButton {
                Button(action: {
                    // Navigation back action will be handled by the parent view
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
            }
            
            if let title = title {
                Text(title)
                    .font(.headline)
                    .padding(.leading, showBackButton ? 8 : 0)
            } else {
                Text("PartyPal")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()
            
            if title == nil {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.title2)
                    
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .offset(x: 6, y: -6)
                }
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.largeTitle)
                        .padding(.leading, 10)
                }
            }
        }
        .padding(2)
    }
}

#Preview {
    VStack {
        HeaderView()
        HeaderView(title: "Chat", showBackButton: true)
    }
}
