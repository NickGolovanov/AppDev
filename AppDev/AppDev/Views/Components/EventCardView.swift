//
//  EventCardView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

import SwiftUI

struct EventCardView: View {
    var title: String

    var body: some View {
        Button(action: {
            // Future: navigate to event detail
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
}

#Preview {
    EventCardView(title: "Sample Event")
}
