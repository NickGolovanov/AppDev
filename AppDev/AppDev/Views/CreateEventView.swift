//
//  CreateEventView.swift
//  AppDev
//
//  Created by Viktor Harhat on 08/05/2025.
//

import SwiftUI

struct CreateEventView: View {
    @State private var eventTitle: String = ""
    @State private var date: Date? = nil
    @State private var category: String = "House Party"
    @State private var startTime: Date? = nil
    @State private var endTime: Date? = nil
    @State private var location: String = ""
    @State private var description: String = ""
    @State private var maxCapacity: Int = 0
    @State private var price: Double = 0.0
    @State private var coverImage: Image? = nil
    @State private var showImagePicker: Bool = false
    
    let categories = ["House Party", "Concert", "Meetup", "Workshop"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20){
                headerSection
                
                imagePickerSection
                eventFormSection
                createButtonSection
                
                footerSection
            }.padding()
        }
    }
}

extension CreateEventView {
    var headerSection: some View {
        HeaderView()
    }
    
    var imagePickerSection: some View {
        Button(action: {
            showImagePicker = true
        }) {
            ZStack {
                Rectangle()
                    .fill(Color(hex: 0xE5E7EB))
                    .frame(height: 192)
                    .cornerRadius(8)
                if let coverImage = coverImage {
                    coverImage
                        .resizable()
                        .scaledToFill()
                        .frame(height: 192)
                        .cornerRadius(8)
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(Color(hex: 0x9CA3AF)).padding(.bottom, 2)
                        Text("Upload Cover Photo")
                            .foregroundColor(Color(hex: 0x6B7280)).font(.custom("Poppins-Regular", size: 14))
                            .fontWeight(.regular)
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $coverImage)
        }
    }
    
    var eventFormSection: some View {
        Group{
            VStack(alignment: .leading, spacing: 8) {
                FormLabel(text: "Event Title")
                StyledTextField(text: $eventTitle, placeholder: "Enter event title")
            }
            
            HStack(spacing: 16){
                VStack(alignment: .leading) {
                    FormLabel(text: "Date")
                    StyledDatePicker(selection: $date, displayedComponents: .date)
                    
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    FormLabel(text: "Category")
                    StyledPicker(selection: $category, options: categories, optionLabel: { $0 })
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    FormLabel(text: "Start Time")
                    StyledDatePicker(selection: $startTime, displayedComponents: .hourAndMinute)
                    
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    FormLabel(text: "End Time")
                    StyledDatePicker(selection: $endTime, displayedComponents: .hourAndMinute)
                }
            }
            
            
            VStack(alignment: .leading, spacing: 8) {
                FormLabel(text: "Location")
                StyledTextField(text: $location, placeholder: "Enter venue address")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                FormLabel(text: "Description")
                StyledTextEditor(text: $description, placeholder: "Describe your event").frame(height: 128)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    FormLabel(text: "Max Capacity")
                    StyledTextField(text: $eventTitle, placeholder: "0").keyboardType(.numberPad)
                    
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    FormLabel(text: "Price (€)")
                    StyledTextField(text: $eventTitle, placeholder: "0.00").keyboardType(.decimalPad)
                }
            }
            
        }
    }
    
    var createButtonSection: some View {
        Button(action: {
            // Handle create event action
        }) {
            Text("Create Event")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    var footerSection: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(height: 60)
            .overlay(
                Text("Footer Placeholder")
                    .font(.footnote)
                    .foregroundColor(.gray)
            )
            .cornerRadius(12)
            .padding(.top, 10)
    }
}

#Preview {
    CreateEventView()
}
