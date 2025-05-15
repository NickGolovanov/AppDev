//
//  HeaderView.swift
//  AppDev
//
//  Created by Viktor Harhat on 12/05/2025.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
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
        .padding(2)
    }
}

#Preview {
    HeaderView()
}
