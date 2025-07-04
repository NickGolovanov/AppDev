import Foundation
import UIKit

class ImageUploadService: ObservableObject {
    static let shared = ImageUploadService()
    
    // Public demo Client ID (works for testing)
    private let clientId = "546c25a59c58ad7"
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    private init() {}
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, ImageUploadError>) -> Void) {
        // Resize image to smaller dimensions first
        let targetSize = CGSize(width: 600, height: 600)
        let resizedImage = image.resized(to: targetSize)
        
        // Compress image
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.5) else {
            completion(.failure(.invalidImage))
            return
        }
        
        // Check size limit (much smaller for better reliability)
        let maxSize = 2 * 1024 * 1024 // 2MB limit
        if imageData.count > maxSize {
            completion(.failure(.uploadFailed("Image too large. Please select a smaller image.")))
            return
        }
        
        print("📸 Resized image size: \(imageData.count) bytes")
        
        // Convert to base64
        let base64String = imageData.base64EncodedString()
        
        // Create URL for Imgur
        guard let url = URL(string: "https://api.imgur.com/3/image") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Update UI
        DispatchQueue.main.async {
            self.isUploading = true
            self.uploadProgress = 0.1
        }
        
        // Create request for Imgur
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Client-ID \(clientId)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Simple form data for Imgur
        let formData = "image=\(base64String)&type=base64&title=ProfileImage"
        request.httpBody = formData.data(using: .utf8)
        
        print("📤 Making request to Imgur...")
        
        // Update progress
        DispatchQueue.main.async {
            self.uploadProgress = 0.3
        }
        
        // Create session with reasonable timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 25
        config.timeoutIntervalForResource = 50
        config.allowsCellularAccess = true
        
        let session = URLSession(configuration: config)
        
        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.uploadProgress = 0.8
            }
            
            // Check for network errors
            if let error = error {
                print("❌ Network error: \(error)")
                print("❌ Error code: \((error as NSError).code)")
                
                DispatchQueue.main.async {
                    self?.isUploading = false
                    self?.uploadProgress = 0.0
                }
                
                if (error as NSError).code == -1005 {
                    completion(.failure(.networkError("Connection lost. Please try again with a smaller image.")))
                } else {
                    completion(.failure(.networkError("Upload failed. Please check your internet connection.")))
                }
                return
            }
            
            // Check response status
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    DispatchQueue.main.async {
                        self?.isUploading = false
                        self?.uploadProgress = 0.0
                    }
                    completion(.failure(.uploadFailed("Server error: HTTP \(httpResponse.statusCode)")))
                    return
                }
            }
            
            guard let data = data else {
                print("❌ No data received")
                DispatchQueue.main.async {
                    self?.isUploading = false
                    self?.uploadProgress = 0.0
                }
                completion(.failure(.noData))
                return
            }
            
            // Debug: Print response
            if let responseString = String(data: data, encoding: .utf8) {
                let truncated = responseString.count > 300 ? String(responseString.prefix(300)) + "..." : responseString
                print("📄 Imgur response: \(truncated)")
            }
            
            // Parse Imgur JSON response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📋 Imgur JSON keys: \(json.keys)")
                    
                    // Imgur response structure: {"data": {"link": "url"}, "success": true}
                    if let success = json["success"] as? Bool, success == true,
                       let dataDict = json["data"] as? [String: Any],
                       let imageURL = dataDict["link"] as? String {
                        
                        print("✅ Imgur upload successful: \(imageURL)")
                        DispatchQueue.main.async {
                            self?.isUploading = false
                            self?.uploadProgress = 1.0
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self?.uploadProgress = 0.0
                            }
                        }
                        completion(.success(imageURL))
                        
                    } else {
                        // Handle Imgur API errors
                        let errorMessage: String
                        if let dataDict = json["data"] as? [String: Any],
                           let error = dataDict["error"] as? String {
                            errorMessage = "Imgur error: \(error)"
                        } else {
                            errorMessage = "Imgur upload failed - Invalid response format"
                        }
                        
                        print("❌ Imgur API error: \(errorMessage)")
                        DispatchQueue.main.async {
                            self?.isUploading = false
                            self?.uploadProgress = 0.0
                        }
                        completion(.failure(.uploadFailed(errorMessage)))
                    }
                } else {
                    print("❌ Invalid JSON response from Imgur")
                    DispatchQueue.main.async {
                        self?.isUploading = false
                        self?.uploadProgress = 0.0
                    }
                    completion(.failure(.invalidResponse))
                }
            } catch {
                print("❌ JSON parsing error: \(error)")
                DispatchQueue.main.async {
                    self?.isUploading = false
                    self?.uploadProgress = 0.0
                }
                completion(.failure(.parsingError(error.localizedDescription)))
            }
        }.resume()
    }
}

// Add this extension for image resizing
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

enum ImageUploadError: Error, LocalizedError {
    case invalidImage
    case invalidURL
    case noData
    case invalidResponse
    case networkError(String)
    case uploadFailed(String)
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process the selected image. Please try a different image."
        case .invalidURL:
            return "Invalid upload URL configuration"
        case .noData:
            return "No response received from server"
        case .invalidResponse:
            return "Invalid server response format"
        case .networkError(let message):
            return message
        case .uploadFailed(let message):
            return message
        case .parsingError(let message):
            return "Response parsing error: \(message)"
        }
    }
}