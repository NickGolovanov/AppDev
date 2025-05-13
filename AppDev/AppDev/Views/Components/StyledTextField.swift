//
//  StyledTextField.swift
//  AppDev
//
//  Created by Viktor Harhat on 08/05/2025.
//

import SwiftUI

struct StyledTextField: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        TextField("", text: $text)
                    .padding(12)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.primary)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: 0xD1D5DB))
                    )
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .padding(12)
                            .foregroundColor(Color(hex: 0xADAEBC))
                            .font(.custom("Poppins-Regular", size: 16))
                    }
    }
}

#Preview {
    @Previewable @State var text = ""
    
    StyledTextField(text: $text, placeholder: "Placeholder")
}
