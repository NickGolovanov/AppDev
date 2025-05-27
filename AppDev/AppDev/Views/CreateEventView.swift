//
//  CreateEventView.swift
//  AppDevp
//
//  Created by Viktor Harhat on 08/05/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct CreateEventView: View {
    @State private var eventTitle: String = ""
    @State private var date: Date? = nil
    @State private var category: String = "House Party"
    @State private var startTime: Date? = nil
    @State private var endTime: Date? = nil
    @State private var location: String = ""
    @State private var description: String = ""
    @State private var maxCapacity: String = ""
    @State private var price: String = ""
    @State private var coverImage: Image? = nil
    @State private var coverUIImage: UIImage? = nil
    @State private var showImagePicker: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isLoading: Bool = false

    let categories = ["House Party", "Concert", "Meetup", "Workshop"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                imagePickerSection
                eventFormSection
                createButtonSection
                footerSection
            }
            .padding()
        }
    }
}

// MARK: - View Sections
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

                if let image = coverUIImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 192)
                        .cornerRadius(8)
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(Color(hex: 0x9CA3AF))
                            .padding(.bottom, 2)
                        Text("Upload Cover Photo")
                            .foregroundColor(Color(hex: 0x6B7280))
                            .font(.custom("Poppins-Regular", size: 14))
                    }
                }
            }
        }
    }

    var eventFormSection: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                FormLabel(text: "Event Title")
                StyledTextField(text: $eventTitle, placeholder: "Enter event title")
            }

            HStack(spacing: 16) {
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
                StyledTextEditor(text: $description, placeholder: "Describe your event")
                    .frame(height: 128)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    FormLabel(text: "Max Capacity")
                    StyledTextField(text: $maxCapacity, placeholder: "0").keyboardType(.numberPad)
                }
                VStack(alignment: .leading, spacing: 8) {
                    FormLabel(text: "Price (€)")
                    StyledTextField(text: $price, placeholder: "0.00").keyboardType(.decimalPad)
                }
            }
        }
    }

    var createButtonSection: some View {
        Button(action: {
            createEvent()
        }) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            } else {
                Text("Create Event")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Event Creation"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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

// MARK: - Event Creation Logic
extension CreateEventView {
    func createEvent() {
        guard !eventTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Event title is required."); return
        }
        guard let eventDate = date else {
            showError("Date is required."); return
        }
        guard !category.isEmpty else {
            showError("Category is required."); return
        }
        guard let start = startTime, let end = endTime else {
            showError("Start and end time are required."); return
        }
        guard end > start else {
            showError("End time must be after start time."); return
        }
        guard !location.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Location is required."); return
        }
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Description is required."); return
        }
        guard let maxCap = Int(maxCapacity), maxCap > 0 else {
            showError("Max capacity must be a positive number."); return
        }
        guard let priceValue = Double(price), priceValue >= 0 else {
            showError("Price must be a non-negative number."); return
        }

        isLoading = true

        if let uiImage = coverUIImage {
            uploadImageAndCreateEvent(uiImage: uiImage)
        } else {
            let defaultImageUrl = "https://firebasestorage.googleapis.com/v0/b/your-app.appspot.com/o/default_event_image.jpg"
            createEventInFirestore(imageUrl: defaultImageUrl)
        }
    }

    private func uploadImageAndCreateEvent(uiImage: UIImage) {
        let storageRef = Storage.storage().reference().child("event_covers/")
        let imageName = UUID().uuidString + ".jpg"
        let imageRef = storageRef.child(imageName)

        guard let imageData = uiImage.jpegData(compressionQuality: 0.8) else {
            showError("Failed to process image data.")
            isLoading = false
            return
        }

        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                showError("Image upload failed: \(error.localizedDescription)")
                isLoading = false
                return
            }

            imageRef.downloadURL { url, error in
                if let error = error {
                    showError("Failed to get image URL: \(error.localizedDescription)")
                    isLoading = false
                    return
                }

                let imageUrl = url?.absoluteString ?? ""
                createEventInFirestore(imageUrl: imageUrl)
            }
        }
    }

    private func createEventInFirestore(imageUrl: String) {
        let db = Firestore.firestore()
        let eventData: [String: Any] = [
            "title": eventTitle,
            "date": ISO8601DateFormatter().string(from: date!),
            "category": category,
            "startTime": ISO8601DateFormatter().string(from: startTime!),
            "endTime": ISO8601DateFormatter().string(from: endTime!),
            "location": location,
            "description": description,
            "maxCapacity": Int(maxCapacity)!,
            "price": Double(price)!,
            "imageUrl": imageUrl,
            "attendees": 0,
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("events").addDocument(data: eventData) { error in
            isLoading = false
            if let error = error {
                showError("Failed to create event: \(error.localizedDescription)")
            } else {
                alertMessage = "Event created successfully!"
                showAlert = true
                // Optional: Reset form fields here
            }
        }
    }

    func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}