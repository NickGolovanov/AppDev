//
//  FormLabelView.swift
//  AppDev
//
//  Created by Viktor Harhat on 08/05/2025.
//

import SwiftUI

struct FormLabel: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.custom("Poppins-Regular", size: 14))
                           .foregroundColor(Color(hex: 0x4B5563))
            
    }
}

#Preview {
    FormLabel(text: "Preview")
}
