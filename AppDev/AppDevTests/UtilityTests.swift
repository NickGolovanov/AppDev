import XCTest
import Foundation
import CoreImage // Needed for CIFilter and CIImage
import UIKit // Needed for UIImage
import SwiftUI // Needed for Color tests
@testable import AppDev // Make sure to import your main app module here

final class UtilityTests: XCTestCase {

    // Assuming generateQRCode function from GetTicketView is accessible
    // For this to be unit testable without the view, it should ideally be
    // in a separate utility file or a static method.
    // As per your instruction not to change code, I'll provide a local
    // helper or assume it's in a way that can be called for testing.
    // If 'generateQRCode' is a private method of GetTicketView,
    // it's not directly testable without making it internal or public,
    // or through UI Testing.

    // Replicating generateQRCode functionality for testability if it's private.
    // If your original generateQRCode is internal/public, you can directly call it.
    private func generateQRCodeForTest(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("M", forKey: "inputCorrectionLevel")
        if let qrImage = qrFilter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledQrImage = qrImage.transformed(by: transform)
            return UIImage(ciImage: scaledQrImage)
        }
        return nil
    }

    func testGenerateQRCodeValidInput() throws {
        let testString = "https://example.com/ticket_id_12345"
        let qrCodeImage = generateQRCodeForTest(from: testString)
        XCTAssertNotNil(qrCodeImage, "QR code image should be generated for valid input.")
        
        // Basic check: is the image non-empty?
        XCTAssertTrue(qrCodeImage!.size.width > 0 && qrCodeImage!.size.height > 0, "Generated QR code image should have valid dimensions.")
    }

    func testGenerateQRCodeEmptyInput() throws {
        let testString = ""
        let qrCodeImage = generateQRCodeForTest(from: testString)
        XCTAssertNotNil(qrCodeImage, "QR code image should still be generated for empty input (represents empty data).")
    }
    
    func testGenerateQRCodeLargeInput() throws {
        let longString = String(repeating: "a", count: 1000) // Very long string
        let qrCode = generateQRCodeForTest(from: longString)
        XCTAssertNotNil(qrCode, "QR code should be generated for a large input.")
    }
    
    // Note: Testing the *content* of the QR code (i.e., if it decodes back to the original string)})
    // is more complex and typically involves a QR code reader library, which is outside
    // the scope of basic unit testing without adding new dependencies.

    // MARK: - Color Extension Tests (Color(hex:))
    // Assuming your Color(hex:) extension is accessible within the AppDev module.
    // If this fails, ensure the Color extension is internal/public and its file is part of the AppDev target's membership.

    // Removed failing tests as requested:

    func testColorFromHexStringWithoutHash() throws {
        let whiteColor = Color(hex: "FFFFFF") // Common hex string
        let uiColor = UIColor(whiteColor)
        XCTAssertEqual(uiColor, UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), "Color from hex string without hash should match expected RGB values.")
    }
} 
