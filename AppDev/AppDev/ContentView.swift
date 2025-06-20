//
//  ContentView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/3/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showRegistration = false
    @StateObject private var logout = AuthViewModel()
    
    var body: some View {
    }
}

#Preview {
    ContentView()
}
