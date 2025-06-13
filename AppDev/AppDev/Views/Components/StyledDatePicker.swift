//
//  StyledDatePicker.swif
//  AppDev
//
//  Created by Viktor Harhat on 09/05/2025.
//

import SwiftUI

struct StyledDatePicker: View {
    @Binding var selection: Date?
    var displayedComponents: DatePicker.Components

    private var formattedDate: String {
        switch displayedComponents {

        case .date:
            if let date = selection {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yyyy"
                return formatter.string(from: date)
            } else {
                return ""
            }
        case .hourAndMinute:
            if let date = selection {
                let formatter = DateFormatter()
                formatter.dateFormat = "hh:mm a"
                return formatter.string(from: date)
            } else {
                return ""
            }
        default:
            return ""
        }

    }

    @State private var tempDate: Date = Date()

    var body: some View {
        DatePicker(
            "",
            selection: Binding(
                get: { selection ?? tempDate },
                set: {
                    tempDate = $0
                    selection = $0
                }
            ),
            displayedComponents: displayedComponents
        )
        .labelsHidden()
        .datePickerStyle(.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(0.0125)
        .font(.custom("Poppins-Regular", size: 16))
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: 0xD1D5DB))
        )
        .overlay(
            Group {
                if selection == nil {
                    Text(displayedComponents == .date ? "mm/dd/yyyy" : "--:-- -")
                        .foregroundColor(Color(hex: 0xADAEBC))
                        .font(.custom("Poppins-Regular", size: 16))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .allowsHitTesting(false)
                } else {
                    Text(formattedDate)
                        .foregroundColor(.primary)
                        .font(.custom("Poppins-Regular", size: 16))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .allowsHitTesting(false)
                }
            }
        )
    }

}

#Preview {
    @Previewable @State var date: Date?

    StyledDatePicker(selection: $date, displayedComponents: .date)
}
