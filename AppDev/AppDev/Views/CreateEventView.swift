//
//  CreateEventView.swift
//  AppDevp
//
//  Created by Viktor Harhat on 08/05/2025.
//

import FirebaseFirestore
import FirebaseStorage
import SwiftUI
import CoreLocation

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userId") var userId: String = ""
    @State private var eventTitle: String = ""
    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil
    @State private var startTime: Date? = nil
    @State private var endTime: Date? = nil
    @State private var category: String = "House Party"
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
    @State private var navigateToEvent = false
    @State private var createdEventId: String = ""

    let categories = [
        "House Party",
        "Concert",
        "Meetup",
        "Workshop",
        "Conference",
        "Exhibition",
        "Festival",
        "Food & Drink",
        "Sports",
        "Theater",
        "Comedy",
        "Networking",
        "Art Gallery",
        "Music Festival",
        "Charity Event",
        "Business Event",
        "Cultural Event",
        "Educational",
        "Fashion Show",
        "Gaming Event"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    imagePickerSection
                    eventFormSection
                    createButtonSection
                }
                .padding()
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToEvent) {
                EventView(eventId: createdEventId)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Event Creation"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
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
                    FormLabel(text: "Start Date")
                    StyledDatePicker(selection: $startDate, displayedComponents: .date)
                }

                VStack(alignment: .leading) {
                    FormLabel(text: "End Date")
                    StyledDatePicker(selection: $endDate, displayedComponents: .date)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    FormLabel(text: "Start Time")
                    StyledDatePicker(selection: $startTime, displayedComponents: .hourAndMinute)
                }

                VStack(alignment: .leading) {
                    FormLabel(text: "End Time")
                    StyledDatePicker(selection: $endTime, displayedComponents: .hourAndMinute)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    FormLabel(text: "Category")
                    StyledPicker(selection: $category, options: categories, optionLabel: { $0 })
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
    }
}

// MARK: - Event Creation Logic
extension CreateEventView {
    func createEvent() {
        guard !eventTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Event title is required.")
            return
        }
        guard let startDate = startDate, let endDate = endDate, let startTime = startTime, let endTime = endTime else {
            showError("Start/end date and time are required.")
            return
        }
        let calendar = Calendar.current
        let startDateTime = calendar.date(bySettingHour: calendar.component(.hour, from: startTime),
                                        minute: calendar.component(.minute, from: startTime),
                                        second: 0,
                                        of: startDate)!
        let endDateTime = calendar.date(bySettingHour: calendar.component(.hour, from: endTime),
                                      minute: calendar.component(.minute, from: endTime),
                                      second: 0,
                                      of: endDate)!
        
        guard endDateTime > startDateTime else {
            showError("End date/time must be after start date/time.")
            return
        }
        
        guard !category.isEmpty else {
            showError("Category is required.")
            return
        }
        guard !location.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Location is required.")
            return
        }
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Description is required.")
            return
        }
        guard let maxCap = Int(maxCapacity), maxCap > 0 else {
            showError("Max capacity must be a positive number.")
            return
        }
        guard let priceValue = Double(price), priceValue >= 0 else {
            showError("Price must be a non-negative number.")
            return
        }

        isLoading = true

        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { placemarks, error in
            guard let placemark = placemarks?.first, let loc = placemark.location else {
                self.isLoading = false
                self.showError("The address could not be found. Please enter a valid address, for example: Van Schaikweg 94, 7811 KL Emmen.")
                return
            }

            let latitude = loc.coordinate.latitude
            let longitude = loc.coordinate.longitude

            if let uiImage = self.coverUIImage {
                self.uploadImageAndCreateEvent(uiImage: uiImage, startDateTime: startDateTime, endDateTime: endDateTime, startTime: startTime, endTime: endTime, latitude: latitude, longitude: longitude)
            } else {
                let defaultImageUrl = "https://firebasestorage.googleapis.com/v0/b/partypal-93790.appspot.com/o/event_covers%2Fdefault.jpg?alt=media&token=e9535113-1b93-4704-a86a-8f7033529342"
                self.createEventInFirestore(imageUrl: defaultImageUrl, startDateTime: startDateTime, endDateTime: endDateTime, startTime: startTime, endTime: endTime, latitude: latitude, longitude: longitude)
            }
        }
    }

    private func uploadImageAndCreateEvent(uiImage: UIImage, startDateTime: Date, endDateTime: Date, startTime: Date, endTime: Date, latitude: Double, longitude: Double) {
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
                self.createEventInFirestore(imageUrl: imageUrl, startDateTime: startDateTime, endDateTime: endDateTime, startTime: startTime, endTime: endTime, latitude: latitude, longitude: longitude)
            }
        }
    }

    private func createEventInFirestore(imageUrl: String, startDateTime: Date, endDateTime: Date, startTime: Date, endTime: Date, latitude: Double, longitude: Double) {
        let db = Firestore.firestore()
        let eventData: [String: Any] = [
            "title": eventTitle,
            "date": ISO8601DateFormatter().string(from: startDateTime),
            "category": category,
            "startTime": ISO8601DateFormatter().string(from: startTime),
            "endTime": ISO8601DateFormatter().string(from: endTime),
            "location": location,
            "description": description,
            "maxCapacity": Int(maxCapacity)!,
            "price": Double(price)!,
            "imageUrl": imageUrl,
            "attendees": 0,
            "createdAt": FieldValue.serverTimestamp(),
            "latitude": latitude,
            "longitude": longitude
        ]

        var newEventRef: DocumentReference? = nil

        newEventRef = db.collection("events").addDocument(data: eventData) { error in
            self.isLoading = false
            if let error = error {
                showError("Failed to create event: \(error.localizedDescription)")
            } else {
                alertMessage = "Event created successfully!"
                showAlert = true
                
                // Add event ID to user's organizedEventIds
                if let eventID = newEventRef?.documentID, !self.userId.isEmpty {
                    let userRef = db.collection("users").document(self.userId)
                    userRef.updateData([
                        "organizedEventIds": FieldValue.arrayUnion([eventID])
                    ]) { err in
                        if let err = err {
                            print("Error updating user organizedEventIds: \(err.localizedDescription)")
                        } else {
                            print("User organizedEventIds updated successfully.")
                            // Dismiss the view after successful creation
                            DispatchQueue.main.async {
                                self.dismiss()
                            }
                        }
                    }
                }
            }
        }
    }

    func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
