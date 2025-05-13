//
//  StyledPicker.swift
//  AppDev
//
//  Created by Viktor Harhat on 09/05/2025.
//

import SwiftUI

struct StyledPicker<T: Hashable>: View {
    @Binding var selection: T
    var options: [T]
    var optionLabel: (T) -> String
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button {
                    $selection.wrappedValue = option
                } label: {
                    Text(optionLabel(option))
                        .font(.custom("Poppins-Regular", size: 16))
                }
            }
        } label: {
            HStack {
                Text(optionLabel($selection.wrappedValue))
                    .foregroundColor(.primary)
                    .font(.custom("Poppins-Regular", size: 16))
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: 0xD1D5DB))
            )
        }
    }
    
}

#Preview {
    @Previewable @State var selection: String = "Apple"
    
    let options = ["Apple", "Banana", "Orange"]
    
    StyledPicker(
        selection: $selection,
        options: options,
        optionLabel: { $0 }
    )
}
