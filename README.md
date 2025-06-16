# Party Pal: Event & Ticketing App

This repository contains the source code for **Party Pal**, a vibrant mobile application designed to simplify the process of creating, discovering, and attending parties and events. It offers a comprehensive suite of functionalities for both event-goers and organizers:

*   **Event Creation & Management:** Organizers can easily create new events, set details like date, time, location, and capacity, and manage attendees.
*   **Event Discovery:** Users can browse a wide variety of events, categorized for easy navigation.
*   **Ticket Purchase & Management:** Attendees can seamlessly purchase tickets for events and manage their purchased tickets within the app.
*   **Profile Management:** Users can customize their profiles, including personal information and event history.
*   **In-App Chat:** Facilitates communication between attendees and organizers, enhancing the social aspect of events.
*   **QR Code Scanning (for Organizers):** Provides organizers with a robust tool to validate tickets at events using QR code scanning, streamlining the check-in process.

## �� Folder Structure

The project follows a standard Xcode project structure, organized to separate application logic from test code.

```
.
├── AppDev/                     # Main application source code
│   ├── Assets.xcassets/        # App assets (images, icons)
│   ├── Models/                 # Data models (e.g., User, Event, Ticket, ChatMessage)
│   ├── Services/               # Service layers for API interactions (e.g., ChatService)
│   ├── Views/                  # SwiftUI views for the user interface
│   ├── AppDevApp.swift         # Main app entry point
│   ├── AppDelegate.swift       # Application delegate for app lifecycle and Firebase setup
│   ├── ContentView.swift       # Main content view
│   └── GoogleService-Info.plist# Firebase configuration file
├── AppDevTests/                # Unit and Integration Tests for application logic
│   ├── AuthViewModelTests.swift
│   ├── ChatServiceTests.swift
│   ├── HomeViewModelTests.swift
│   ├── ModelsTests.swift
│   ├── QRCodeScannerIntegrationTests.swift # Comprehensive integration tests for QR scanning
│   └── UtilityTests.swift
├── AppDevUITests/              # User Interface Tests
├── AppDev.xcodeproj/           # Xcode project configuration
└── GoogleService-Info.plist    # Firebase configuration (duplicate, often used at root for convenience)
```

## 🚀 Key Technologies Used

*   **SwiftUI:** Declarative UI framework for building the application interface.
*   **Firebase:**
    *   **Firestore:** NoSQL cloud database for storing application data (users, events, tickets, chats).
    *   **Firebase Authentication:** For user registration and login.
    *   **Firebase Storage:** For storing user-generated content like profile images.
*   **Combine:** For reactive programming and handling asynchronous operations.
*   **XCTest:** Apple's native testing framework for unit and integration tests.
*   **CoreImage & UIKit:** Used for QR code generation.

## 🛠️ Setup Instructions

Follow these steps to set up and run the AppDev project locally on your machine.

### 1. Local Setup

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/your-username/AppDev.git # Replace with your actual repo URL
    cd AppDev
    ```
2.  **Open in Xcode:**
    Open the `AppDev.xcodeproj` file in Xcode.
3.  **Install Dependencies (if applicable):**
    This project likely uses Swift Package Manager (SPM) for Firebase dependencies. Xcode should automatically resolve these when you open the project. If not, ensure you have the Firebase SDKs linked correctly via SPM in your project settings.

### 2. Environment Variables / Firebase Configuration

This project relies on Firebase. You need to link your own Firebase project to this application.

1.  **Create a Firebase Project:**
    Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
2.  **Add an iOS App:**
    Follow the Firebase setup wizard to add an iOS application to your project.
3.  **Download `GoogleService-Info.plist`:**
    During the setup, download the `GoogleService-Info.plist` file.
4.  **Add to Xcode:**
    Drag and drop this `GoogleService-Info.plist` file into your `AppDev` folder in Xcode's Project Navigator. Make sure it's added to the `AppDev` target. (You may have two copies, one at the root and one in `AppDev/AppDev`; ensure the one in `AppDev/AppDev` is correctly configured for the target).

### 3. Running the Application

1.  **Select a Target:**
    In Xcode, select the `AppDev` target from the scheme selector.
2.  **Choose a Simulator or Device:**
    Select your desired iOS Simulator or a connected physical device.
3.  **Build and Run:**
    Click the "Run" button (▶️) or go to `Product` > `Run`.

## 🧪 How to Run Tests

The project includes various types of tests that can be run directly from Xcode.

1.  **Open Test Navigator:**
    In Xcode, navigate to the Test Navigator (CMD + 6, or the diamond icon in the left sidebar).
2.  **Run All Tests:**
    Click the "Play" button (▶️) next to the `AppDevTests` target to run all unit and integration tests.
3.  **Run Individual Tests/Suites:**
    You can also run specific test classes or individual test methods by clicking the "Play" button next to them in the Test Navigator.

### Important Notes for Integration Tests:

*   The `QRCodeScannerIntegrationTests.swift` interact with your **live Firebase project**.
*   Ensure your **Firestore security rules** are configured to allow the necessary read/write operations for users, events, and tickets as simulated by the tests.
*   For a more isolated and repeatable testing environment, consider setting up and using the **Firebase Local Emulator Suite**. This would prevent tests from affecting your live development data.

## 📄 Documentation

(Add links to any external documentation, API references, or deployment guides here if applicable.) 