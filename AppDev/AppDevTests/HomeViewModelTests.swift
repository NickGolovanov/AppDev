import XCTest
import Foundation
import FirebaseFirestore
import Combine
@testable import AppDev // Import your main app module

final class HomeViewModelTests: XCTestCase {

    var homeViewModel: HomeViewModel!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        homeViewModel = HomeViewModel()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDownWithError() throws {
        homeViewModel = nil
        cancellables = nil
    }

    func testInitialState() throws {
        XCTAssertTrue(homeViewModel.upcomingEvents.isEmpty, "Upcoming events should be empty initially.")
        XCTAssertFalse(homeViewModel.isLoading, "isLoading should be false initially.")
        XCTAssertNil(homeViewModel.errorMessage, "errorMessage should be nil initially.")
    }

    func testFetchEventsSetsLoadingState() async throws {
        // This test only verifies the immediate loading state change
        let expectation = self.expectation(description: "isLoading should become true")
        
        homeViewModel.$isLoading
            .dropFirst() // Drop initial false value
            .sink { isLoading in
                if isLoading { // Check if it turns true
                    XCTAssertTrue(isLoading, "isLoading should be true when fetchEvents starts.")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        homeViewModel.fetchEvents()
        
        await fulfillment(of: [expectation], timeout: 1.0)
        // Note: We don't assert isLoading becomes false here because fetchEvents is async
        // and its completion depends on Firebase response.
    }
    
    func testFetchEventsIntegration() async throws {
        // This is an integration-like test, it will hit real Firebase.
        // Its success depends on your Firebase setup and network access.
        let expectation = self.expectation(description: "fetchEvents should complete")
        
        // Observe when isLoading turns false (indicating completion) or errorMessage appears
        homeViewModel.$isLoading
            .dropFirst() // Drop initial false
            .sink { isLoading in
                if !isLoading { // When it becomes false again
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        homeViewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                if errorMessage != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        homeViewModel.fetchEvents()
        
        await fulfillment(of: [expectation], timeout: 10.0) // Give enough time for Firebase call
        
        // Assert based on expected outcome (e.g., if events are fetched or error occurred)
        if homeViewModel.errorMessage == nil {
            XCTAssertFalse(homeViewModel.upcomingEvents.isEmpty, "If no error, upcomingEvents should not be empty after fetch.")
        } else {
            XCTAssertTrue(homeViewModel.upcomingEvents.isEmpty, "If error, upcomingEvents should be empty.")
            XCTAssertNotNil(homeViewModel.errorMessage, "If error, errorMessage should not be nil.")
        }
    }
} 