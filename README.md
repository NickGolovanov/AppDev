# Party Pal: Event & Ticketing App

A modern iOS application built with SwiftUI for event discovery, management, and social interaction. This app allows users to create, discover, and attend events while providing features like real-time chat, QR code ticketing, and location-based event mapping.

## 🚀 Features

### Core Functionality

- **User Authentication**: Secure login and registration with Firebase Auth
- **Event Creation & Management**: Organizers can easily create new events, set details like date, time, location, and capacity, and manage attendees
- **Event Discovery**: Browse events by category, location, and date
- **Interactive Maps**: View events on an interactive map with location services
- **Ticket Purchase & Management**: Attendees can seamlessly purchase tickets for events and manage their purchased tickets within the app
- **QR Code Ticketing**: Generate and scan QR codes for event tickets
- **Real-time Chat**: In-app messaging system for event attendees
- **Profile Management**: User profiles with customizable information and event history
- **Image Upload**: Profile pictures and event images with Firebase Storage

### Technical Features

- **Firebase Integration**: Complete backend with Firestore, Auth, Storage, and Analytics
- **Location Services**: MapKit integration for location-based features
- **Real-time Updates**: Live data synchronization across the app
- **Modern UI**: Beautiful SwiftUI interface with custom components
- **Responsive Design**: Optimized for different iOS device sizes

## 🛠 Tech Stack

- **Frontend**: SwiftUI, UIKit
- **Backend**: Firebase (Firestore, Auth, Storage, Analytics)
- **Maps**: MapKit, Core Location
- **QR Code**: AVFoundation for camera access
- **Architecture**: MVVM with ObservableObject
- **iOS Version**: iOS 14.0+
- **Combine**: For reactive programming and handling asynchronous operations
- **XCTest**: Apple's native testing framework for unit and integration tests
- **CoreImage & UIKit**: Used for QR code generation

## 📡 APIs Used

This project interacts with several APIs, primarily through Firebase and Firestore, as well as an external QR code generation service:

### Firestore Collections

- **users**: Stores user profiles and metadata (e.g., email, full name, username, description, profile image URL, joined/organized event IDs).
- **events**: Stores event details (title, date, time, location, image URL, attendees, category, price, max capacity, description, coordinates, etc.).
- **tickets**: Stores ticket information for users and events (eventId, eventName, userId, name, email, price, QR code URL, status, etc.).
- **chats**: Stores chat metadata for each event or ticket (eventId, eventName, lastMessage, lastMessageTime, etc.).
- **chats/{chatId}/messages**: Stores individual chat messages for each chat (content, senderId, senderName, timestamp, etc.).

### Firebase Authentication

- Used for user registration, login, and authentication (including Google Sign-In).

### Firebase Storage

- Used for storing event cover images and user profile images.

### External APIs

- **QR Code Generation**: [api.qrserver.com/v1/create-qr-code/](https://api.qrserver.com/v1/create-qr-code/) is used to generate QR codes for tickets.

These APIs are accessed via the Firebase SDKs and REST endpoints as appropriate within the app's Swift codebase.

## 📋 Prerequisites

Before running this project, make sure you have:

- **Xcode 14.0+** installed
- **iOS 14.0+** deployment target
- **Apple Developer Account** (for device testing)
- **Firebase Project** set up
- **CocoaPods** or **Swift Package Manager** for dependencies

## 🛠️ Setup Instructions

Follow these steps to set up and run the AppDev project locally on your machine.

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/AppDev.git # Replace with your actual repo URL
cd AppDev
```

### 2. Firebase Configuration

#### Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Enable the following services:
   - **Authentication** (Email/Password)
   - **Firestore Database**
   - **Storage**
   - **Analytics** (optional)

#### Download GoogleService-Info.plist

1. In Firebase Console, go to Project Settings
2. Add iOS app with your bundle identifier: `NikitaGolovanov.AppDev`
3. Download the `GoogleService-Info.plist` file
4. Place it in the root of your project (same level as the `.xcodeproj` file)

#### Configure Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Events can be read by all authenticated users, written by creators
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == resource.data.creatorId;
    }

    // Chat messages can be read/written by authenticated users
    match /chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### Configure Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 3. Dependencies Installation

#### Using Swift Package Manager (Recommended)

1. Open the project in Xcode
2. Go to File → Add Package Dependencies
3. Add the following Firebase packages:
   - `https://github.com/firebase/firebase-ios-sdk.git`
   - Select these products:
     - FirebaseAuth
     - FirebaseFirestore
     - FirebaseStorage
     - FirebaseAnalytics
     - FirebaseAppCheck

#### Using CocoaPods (Alternative)

1. Create a `Podfile` in the project root:

```ruby
platform :ios, '14.0'

target 'AppDev' do
  use_frameworks!

  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'Firebase/Analytics'
  pod 'Firebase/AppCheck'
end
```

2. Run installation:

```bash
pod install
```

### 4. Build and Run

1. Open `AppDev.xcworkspace` (if using CocoaPods) or `AppDev.xcodeproj`
2. Select your target device or simulator
3. Build and run the project (⌘+R)

## 🔐 Environment Variables & Configuration

### Required Configuration Files

- `GoogleService-Info.plist` - Firebase configuration (already included)
- Bundle Identifier: `NikitaGolovanov.AppDev`

### Optional Configuration

- **App Check**: Currently using debug provider for development
- **Analytics**: Configured but disabled by default
- **Push Notifications**: Not implemented but can be added

## 📁 Project Structure

The project follows a standard Xcode project structure, organized to separate application logic from test code.

```
.
├── AppDev/                     # Main application source code
│   ├── AppDev/
│   │   ├── AppDevApp.swift     # Main app entry point
│   │   ├── AppDelegate.swift   # Application delegate for app lifecycle and Firebase setup
│   │   ├── ContentView.swift   # Main content view
│   │   ├── Assets.xcassets/    # App assets (images, icons)
│   │   ├── Models/             # Data models (e.g., User, Event, Ticket, ChatMessage)
│   │   ├── Services/           # Service layers for API interactions (e.g., ChatService)
│   │   ├── Views/              # SwiftUI views for the user interface
│   │   │   ├── Components/     # Reusable UI components
│   │   │   ├── LoginView.swift
│   │   │   ├── RegistrationView.swift
│   │   │   ├── HomeView.swift
│   │   │   ├── EventsView.swift
│   │   │   ├── CreateEventView.swift
│   │   │   ├── ChatView.swift
│   │   │   ├── ProfileView.swift
│   │   │   └── ...
│   │   └── GoogleService-Info.plist # Firebase configuration file
│   ├── AppDevTests/            # Unit and Integration Tests for application logic
│   │   ├── AuthViewModelTests.swift
│   │   ├── ChatServiceTests.swift
│   │   ├── HomeViewModelTests.swift
│   │   ├── ModelsTests.swift
│   │   ├── QRCodeScannerIntegrationTests.swift # Comprehensive integration tests for QR scanning
│   │   └── UtilityTests.swift
│   ├── AppDevUITests/          # User Interface Tests
│   ├── AppDev.xcodeproj/       # Xcode project configuration
│   ├── backend/                # Backend server files
│   └── GoogleService-Info.plist # Firebase configuration (duplicate, often used at root for convenience)
└── README.md                   # This file
```

## 🧪 How to Run Tests

The project includes various types of tests that can be run directly from Xcode.

1. **Open Test Navigator:**
   In Xcode, navigate to the Test Navigator (CMD + 6, or the diamond icon in the left sidebar).
2. **Run All Tests:**
   Click the "Play" button (▶️) next to the `AppDevTests` target to run all unit and integration tests.
3. **Run Individual Tests/Suites:**
   You can also run specific test classes or individual test methods by clicking the "Play" button next to them in the Test Navigator.

### Important Notes for Integration Tests:

- The `QRCodeScannerIntegrationTests.swift` interact with your **live Firebase project**.
- Ensure your **Firestore security rules** are configured to allow the necessary read/write operations for users, events, and tickets as simulated by the tests.
- For a more isolated and repeatable testing environment, consider setting up and using the **Firebase Local Emulator Suite**. This would prevent tests from affecting your live development data.

## 🚀 Deployment

### Development

- Use iOS Simulator or connected device
- Firebase App Check is in debug mode
- Analytics events are logged for testing

### Production

1. **Update Bundle Identifier**: Change to your production bundle ID
2. **Firebase Configuration**: Update `GoogleService-Info.plist` with production Firebase project
3. **App Check**: Switch to production App Check provider
4. **Code Signing**: Configure with your Apple Developer account
5. **App Store Connect**: Upload build for review

## 🔧 Troubleshooting

### Common Issues

#### Firebase Connection Issues

- Verify `GoogleService-Info.plist` is in the correct location
- Check Firebase project configuration
- Ensure all required Firebase services are enabled

#### Build Errors

- Clean build folder (⌘+Shift+K)
- Reset package caches in Xcode
- Verify all dependencies are properly installed

#### Permission Issues

- Camera access for QR scanning
- Location services for maps
- Photo library access for image uploads

### Debug Mode

The app includes debug logging for Firebase operations. Check Xcode console for detailed logs.

## 📄 Documentation

- **Project Overview & Features:** See the top of this README for a summary of app features and architecture.
- **API Reference:** The 'APIs Used' section above details all Firestore collections, authentication, storage, and external APIs used by the app.
- **Setup & Configuration:** See the 'Setup Instructions' section for step-by-step guidance on running the app locally and configuring Firebase.
- **Testing:** The 'How to Run Tests' section explains how to run unit and integration tests, and notes about integration with live Firebase data.
- **External References:**
  - [Firebase Documentation](https://firebase.google.com/docs)
  - [Firestore Documentation](https://firebase.google.com/docs/firestore)
  - [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
  - [QRServer API Docs](https://goqr.me/api/)

For further details on app architecture, data models, or contributing, please refer to the relevant sections above or contact the maintainers.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Authors

**Cristian Trifan**
**Nikita Golovanov**
**Mihail Josan**
**Do Do**

## 🙏 Acknowledgments

- Firebase team for the excellent backend services
- Apple for SwiftUI and iOS development tools
- Open source community for various libraries and resources

---

**Note**: This is a development version. For production use, ensure proper security configurations and testing.
