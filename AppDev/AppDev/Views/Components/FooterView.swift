//
//  FooterView.swift
//  AppDev
//
//  Created by Viktor Harhat on 12/05/2025.
//

import SwiftUI

struct FooterView: View {
	@Binding var selectedTab: String

	var body: some View {
		HStack {
			Spacer()
			VStack {
				Image(systemName: "house.fill")
					.foregroundColor(selectedTab == "Home" ? .purple : .gray)
				Text("Home").font(.caption)
					.foregroundColor(selectedTab == "Home" ? .purple : .gray)
			}
			.onTapGesture {
				withAnimation {
					selectedTab = "Home"
				}
			}
			Spacer()
			VStack {
				Image(systemName: "ticket.fill")
					.foregroundColor(selectedTab == "Tickets" ? .purple : .gray)
				Text("Tickets").font(.caption)
					.foregroundColor(selectedTab == "Tickets" ? .purple : .gray)
			}
			.onTapGesture {
				withAnimation {
					selectedTab = "Tickets"
				}
			}
			Spacer()
			VStack {
				Image(systemName: "map.fill")
					.foregroundColor(selectedTab == "Map" ? .purple : .gray)
				Text("Map").font(.caption)
					.foregroundColor(selectedTab == "Map" ? .purple : .gray)
			}
			.onTapGesture {
				withAnimation {
					selectedTab = "Map"
				}
			}
			Spacer()
			VStack {
				Image(systemName: "bubble.left.and.bubble.right.fill")
					.foregroundColor(selectedTab == "Chat" ? .purple : .gray)
				Text("Chat").font(.caption)
					.foregroundColor(selectedTab == "Chat" ? .purple : .gray)
			}
			.onTapGesture {
				withAnimation {
					selectedTab = "Chat"
				}
			}
			Spacer()
		}
		.padding(.vertical, 8)
		.background(Color.white)
		.shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: -1)
	}
}

#Preview {
	FooterView(selectedTab: .constant("Home"))
}
