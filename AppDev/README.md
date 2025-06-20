# AppDev - PartyPal

A modern iOS application built with SwiftUI for event discovery, management, and social interaction. This app allows users to create, discover, and attend events while providing features like real-time chat, QR code ticketing, and location-based event mapping.

## 🚀 Features

### Core Functionality
- **User Authentication**: Secure login and registration with Firebase Auth
- **Event Management**: Create, edit, and manage events with rich details
- **Event Discovery**: Browse events by category, location, and date
- **Interactive Maps**: View events on an interactive map with location services
- **QR Code Ticketing**: Generate and scan QR codes for event tickets
- **Real-time Chat**: In-app messaging system for event attendees
- **Profile Management**: User profiles with customizable information
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

## 📋 Prerequisites

Before running this project, make sure you have:

- **Xcode 14.0+** installed
- **iOS 14.0+** deployment target
- **Apple Developer Account** (for device testing)
- **Firebase Project** set up
- **CocoaPods** or **Swift Package Manager** for dependencies

## 🔧 Installation & Setup

### 1. Clone the Repository
```bash
git clone [your-repository-url]
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

```
AppDev/
├── AppDev/
│   ├── AppDevApp.swift          # Main app entry point
│   ├── AppDelegate.swift        # Firebase configuration
│   ├── ContentView.swift        # Root view
│   ├── Models/                  # Data models
│   │   ├── Event.swift
│   │   ├── User.swift
│   │   ├── ChatModels.swift
│   │   └── HomeViewModel.swift
│   ├── Views/                   # UI Views
│   │   ├── Components/          # Reusable UI components
│   │   ├── LoginView.swift
│   │   ├── RegistrationView.swift
│   │   ├── HomeView.swift
│   │   ├── EventsView.swift
│   │   ├── CreateEventView.swift
│   │   ├── ChatView.swift
│   │   ├── ProfileView.swift
│   │   └── ...
│   └── Assets.xcassets/         # Images and assets
├── GoogleService-Info.plist     # Firebase configuration
└── AppDev.xcodeproj/           # Xcode project file
```

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

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

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