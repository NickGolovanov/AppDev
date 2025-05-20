//
//  MainTabView.swift
//  AppDev
//
//  Created by Viktor Harhat on 12/05/2025.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = "Home"

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag("Home")
                    .ignoresSafeArea(.all, edges: .bottom)

                TicketsView()
                    .tag("Tickets")
                    .ignoresSafeArea(.all, edges: .bottom)

                EventsView()
                    .tag("Events")
                    .ignoresSafeArea(.all, edges: .bottom)

                ChatView()
                    .tag("Chat")
                    .ignoresSafeArea(.all, edges: .bottom)

                ProfileView()
                    .tag("Profile")
                    .ignoresSafeArea(.all, edges: .bottom)
            }
            .tabViewStyle(.automatic)
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                Spacer()
                FooterView(selectedTab: $selectedTab)
                    .frame(height: 60)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    MainTabView()
}
