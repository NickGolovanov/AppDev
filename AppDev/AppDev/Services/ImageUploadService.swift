import Foundation
import UIKit

class ImageUploadService: ObservableObject {
    static let shared = ImageUploadService()
    
    // Your ImgBB API key
    private let apiKey = "be5db19812c55baa1f51a989b68fa51f"
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    private init() {}
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, ImageUploadError>) -> Void) {
        // Compress image aggressively to reduce size and potential network issues
        guard let imageData = image.jpegData(compressionQuality: 0.3) else {
            completion(.failure(.invalidImage))
            return
        }
        
        // Much smaller size limit to avoid network timeouts
        let maxSize = 5 * 1024 * 1024 // 5MB limit
        if imageData.count > maxSize {
            completion(.failure(.uploadFailed("Image too large. Please select a smaller image.")))
            return
        }
        
        print("📸 Image size: \(imageData.count) bytes")
        
        // Convert to base64
        let base64String = imageData.base64EncodedString()
        
        // Validate base64 string
        guard !base64String.isEmpty else {
            completion(.failure(.invalidImage))
            return
        }
        
        // Create URL
        guard let url = URL(string: "https://api.imgbb.com/1/upload") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Update UI
        DispatchQueue.main.async {
            self.isUploading = true
            self.uploadProgress = 0.1
        }
        
        // Use simple URL-encoded form data instead of multipart
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Encode parameters properly
        let parameters = [
            "key": apiKey,
            "image": base64String,
            "name": "profile_image_\(Int(Date().timeIntervalSince1970))"
        ]
        
        // Create form-encoded body
        let formData = parameters.compactMap { key, value in
            guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
        
        request.httpBody = formData.data(using: .utf8)
        
        print("📤 Making request to ImgBB...")
        
        // Update progress
        DispatchQueue.main.async {
            self.uploadProgress = 0.3
        }
        
        // Create session with shorter timeout to fail fast if there are issues
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30 // Shorter timeout
        config.timeoutIntervalForResource = 60
        config.allowsCellularAccess = true
        config.waitsForConnectivity = false
        
        let session = URLSession(configuration: config)
        
        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.uploadProgress = 0.8
            }
            
            // Check for network errors
            if let error = error {
                print("❌ Network error: \(error)")
                print("❌ Error code: \((error as NSError).code)")
                print("❌ Error domain: \((error as NSError).domain)")
                
                DispatchQueue.main.async {
                    self?.isUploading = false
                    self?.uploadProgress = 0.0
                }
                
                // Provide more specific error messages
                if (error as NSError).code == -1005 {
                    completion(.failure(.networkError("Network connection lost. Please check your internet and try again.")))
                } else if (error as NSError).code == -1001 {
                    completion(.failure(.networkError("Upload timed out. Please try with a smaller image.")))
                } else {
                    completion(.failure(.networkError("Network error: \(error.localizedDescription)")))
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
            
            // Debug: Print raw response (truncated for large responses)
            if let responseString = String(data: data, encoding: .utf8) {
                let truncated = responseString.count > 500 ? String(responseString.prefix(500)) + "..." : responseString
                print("📄 Raw response: \(truncated)")
            }
            
            // Parse JSON response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📋 Parsed JSON keys: \(json.keys)")
                    
                    if let success = json["success"] as? Bool, success == true,
                       let dataDict = json["data"] as? [String: Any],
                       let imageURL = dataDict["url"] as? String {
                        
                        print("✅ Upload successful: \(imageURL)")
                        DispatchQueue.main.async {
                            self?.isUploading = false
                            self?.uploadProgress = 1.0
                            // Reset progress after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self?.uploadProgress = 0.0
                            }
                        }
                        completion(.success(imageURL))
                        
                    } else {
                        // Handle API errors
                        let errorMessage: String
                        if let error = json["error"] as? [String: Any] {
                            if let message = error["message"] as? String {
                                errorMessage = message
                            } else {
                                errorMessage = "API error: \(error)"
                            }
                        } else if let statusCode = json["status"] as? Int {
                            errorMessage = "API error with status \(statusCode)"
                        } else {
                            errorMessage = "Unknown API error - Response: \(json)"
                        }
                        
                        print("❌ API error: \(errorMessage)")
                        DispatchQueue.main.async {
                            self?.isUploading = false
                            self?.uploadProgress = 0.0
                        }
                        completion(.failure(.uploadFailed(errorMessage)))
                    }
                } else {
                    print("❌ Invalid JSON response")
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