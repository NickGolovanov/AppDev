//
//  StyledTextEditor.swift
//  AppDev
//
//  Created by Viktor Harhat on 09/05/2025.
//

import SwiftUI

struct StyledTextEditor: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        TextEditor(text: $text)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: 0xD1D5DB))
            )
            .scrollContentBackground(.hidden)
            .placeholder(when: text.isEmpty, alignment: .topLeading) {
                Text(placeholder)
                    .padding(20)
                    .foregroundColor(Color(hex: 0xADAEBC))
                    .font(.custom("Poppins-Regular", size: 16))
            }
    }
}

#Preview {
    @Previewable @State var text: String = ""
    let placeholder: String = "Placeholder"
    
    StyledTextEditor(text: $text, placeholder: placeholder).frame(height: 128)
}
