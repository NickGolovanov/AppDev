//
//  ContentView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/3/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showRegistration = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .imageScale(.large)
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("Welcome to AppDev")
                    .font(.title)
                    .fontWeight(.bold)
                
                Button(action: {
                    showRegistration = true
                }) {
                    Text("Create Account")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .sheet(isPresented: $showRegistration) {
                RegistrationView()
            }
        }
    }
}

#Preview {
    ContentView()
}
