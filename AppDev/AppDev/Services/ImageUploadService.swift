import Foundation
import UIKit

class ImageUploadService: ObservableObject {
    static let shared = ImageUploadService()
    
    // Replace with your actual ImgBB API key
    private let apiKey = "be5db19812c55baa1f51a989b68fa51f"
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    private init() {}
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, ImageUploadError>) -> Void) {
        // Compress image to reduce upload time and ensure compatibility
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(.invalidImage))
            return
        }
        
        // Convert to base64 and ensure it's properly encoded
        let base64String = imageData.base64EncodedString(options: [])
        
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
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Create form data with proper URL encoding
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "image", value: base64String),
            URLQueryItem(name: "name", value: "profile_image_\(Int(Date().timeIntervalSince1970))")
        ]
        
        // Get the properly encoded query string
        guard let queryString = components.percentEncodedQuery else {
            DispatchQueue.main.async {
                self.isUploading = false
                self.uploadProgress = 0.0
            }
            completion(.failure(.invalidURL))
            return
        }
        
        request.httpBody = queryString.data(using: .utf8)
        
        // Update progress
        DispatchQueue.main.async {
            self.uploadProgress = 0.5
        }
        
        // Make request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.uploadProgress = 0.9
            }
            
            // Check for network errors
            if let error = error {
                DispatchQueue.main.async {
                    self?.isUploading = false
                    self?.uploadProgress = 0.0
                }
                completion(.failure(.networkError(error.localizedDescription)))
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
                    completion(.failure(.uploadFailed("HTTP \(httpResponse.statusCode)")))
                    return
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.isUploading = false
                    self?.uploadProgress = 0.0
                }
                completion(.failure(.noData))
                return
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(responseString)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📋 Parsed JSON: \(json)")
                    
                    if let success = json["success"] as? Bool, success == true,
                       let dataDict = json["data"] as? [String: Any],
                       let imageURL = dataDict["url"] as? String {
                        
                        DispatchQueue.main.async {
                            self?.isUploading = false
                            self?.uploadProgress = 1.0
                            // Reset progress after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self?.uploadProgress = 0.0
                            }
                        }
                        completion(.success(imageURL))
                    } else {
                        // Handle API errors
                        if let error = json["error"] as? [String: Any],
                           let message = error["message"] as? String {
                            DispatchQueue.main.async {
                                self?.isUploading = false
                                self?.uploadProgress = 0.0
                            }
                            completion(.failure(.uploadFailed(message)))
                        } else {
                            DispatchQueue.main.async {
                                self?.isUploading = false
                                self?.uploadProgress = 0.0
                            }
                            completion(.failure(.uploadFailed("Unknown API error")))
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.isUploading = false
                        self?.uploadProgress = 0.0
                    }
                    completion(.failure(.invalidResponse))
                }
            } catch {
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
            return "Network error: \(message)"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .parsingError(let message):
            return "Response parsing error: \(message)"
        }
    }
}