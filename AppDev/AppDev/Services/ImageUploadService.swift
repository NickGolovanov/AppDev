import Foundation
import UIKit

class ImageUploadService: ObservableObject {
    static let shared = ImageUploadService()
    
    private let apiKey = "be5db19812c55baa1f51a989b68fa51f"
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    private init() {}
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, ImageUploadError>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(.invalidImage))
            return
        }
        
        // Convert to base64
        let base64String = imageData.base64EncodedString()
        
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
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = "key=\(apiKey)&image=\(base64String)&name=event_image_\(Date().timeIntervalSince1970)"
        request.httpBody = parameters.data(using: .utf8)
        
        DispatchQueue.main.async {
            self.uploadProgress = 0.5
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.uploadProgress = 0.9
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self?.isUploading = false
                    self?.uploadProgress = 0.0
                }
                completion(.failure(.networkError(error.localizedDescription)))
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.isUploading = false
                    self?.uploadProgress = 0.0
                }
                completion(.failure(.noData))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let success = json["success"] as? Bool, success == true,
                       let dataDict = json["data"] as? [String: Any],
                       let imageURL = dataDict["url"] as? String {
                        
                        DispatchQueue.main.async {
                            self?.isUploading = false
                            self?.uploadProgress = 1.0
                        }
                        completion(.success(imageURL))
                    } else {
                        let errorMessage = json["error"] as? [String: Any]
                        let message = errorMessage?["message"] as? String ?? "Upload failed"
                        
                        DispatchQueue.main.async {
                            self?.isUploading = false
                            self?.uploadProgress = 0.0
                        }
                        completion(.failure(.uploadFailed(message)))
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
            return "Invalid image format"
        case .invalidURL:
            return "Invalid upload URL"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid server response"
        case .networkError(let message):
            return "Network error: \(message)"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}