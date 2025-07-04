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
        // Compress image more aggressively for better compatibility
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            completion(.failure(.invalidImage))
            return
        }
        
        // Check file size (ImgBB free tier has 32MB limit)
        let maxSize = 16 * 1024 * 1024 // 16MB to be safe
        if imageData.count > maxSize {
            completion(.failure(.uploadFailed("Image too large. Please select a smaller image.")))
            return
        }
        
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
        
        // Create multipart form data manually (more reliable)
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build form data
        var formData = Data()
        
        // Add API key
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"key\"\r\n\r\n".data(using: .utf8)!)
        formData.append("\(apiKey)\r\n".data(using: .utf8)!)
        
        // Add image data
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"image\"\r\n\r\n".data(using: .utf8)!)
        formData.append("\(base64String)\r\n".data(using: .utf8)!)
        
        // Add optional name
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
        formData.append("profile_image_\(Int(Date().timeIntervalSince1970))\r\n".data(using: .utf8)!)
        
        // End boundary
        formData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        // Update progress
        DispatchQueue.main.async {
            self.uploadProgress = 0.3
        }
        
        // Make request with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        let session = URLSession(configuration: config)
        
        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.uploadProgress = 0.8
            }
            
            // Check for network errors
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
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
                    completion(.failure(.uploadFailed("Server returned status \(httpResponse.statusCode)")))
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
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(responseString)")
            }
            
            // Parse JSON response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📋 Parsed JSON: \(json)")
                    
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
                        if let error = json["error"] as? [String: Any],
                           let message = error["message"] as? String {
                            errorMessage = message
                        } else if let statusCode = json["status"] as? Int {
                            errorMessage = "API error with status \(statusCode)"
                        } else {
                            errorMessage = "Unknown API error"
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
            return "Network error: \(message)"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .parsingError(let message):
            return "Response parsing error: \(message)"
        }
    }
}