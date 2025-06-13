//
//  MainTabView.swift
//  AppDev
//
//  Created by Viktor Harhat on 12/05/2025.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = "Home"
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                EventsView()
                    .tag("Home")
                    .ignoresSafeArea(.all, edges: .bottom)

                TicketsView()
                    .tag("Tickets")
                    .ignoresSafeArea(.all, edges: .bottom)

                EventsMapView()
                    .tag("Map")
                    .ignoresSafeArea(.all, edges: .bottom)

                ChatView(authViewModel: authViewModel)
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
        .environmentObject(AuthViewModel())
}
