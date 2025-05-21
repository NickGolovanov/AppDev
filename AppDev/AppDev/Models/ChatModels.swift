import Foundation
import FirebaseFirestore

struct ChatItem: Identifiable, Codable {
    let id: String
    let eventId: String
    let eventName: String
    let iconName: String
    let lastMessage: String
    let lastMessageTime: Date
    let unreadCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId
        case eventName
        case iconName
        case lastMessage
        case lastMessageTime
        case unreadCount
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: String
    let eventId: String
    let content: String
    let senderId: String
    let senderName: String
    let timestamp: Date
    let isFromCurrentUser: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId
        case content
        case senderId
        case senderName
        case timestamp
        case isFromCurrentUser
    }
}

// Firebase Chat Service
class ChatService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var chats: [ChatItem] = []
    @Published var messages: [String: [ChatMessage]] = [:] // eventId: messages
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    func fetchUserChats() async throws {
        guard let userId = userId else { return }
        
        // Get user's tickets
        let ticketsSnapshot = try await db.collection("tickets")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        // Get chats for each ticket's event
        for ticketDoc in ticketsSnapshot.documents {
            let ticketData = ticketDoc.data()
            guard let eventId = ticketData["eventId"] as? String else { continue }
            
            // Get chat info
            let chatDoc = try await db.collection("chats")
                .document(eventId)
                .getDocument()
            
            if let chatData = chatDoc.data() {
                let chat = ChatItem(
                    id: eventId,
                    eventId: eventId,
                    eventName: chatData["eventName"] as? String ?? "",
                    iconName: "bubble.left.and.bubble.right.fill",
                    lastMessage: chatData["lastMessage"] as? String ?? "",
                    lastMessageTime: (chatData["lastMessageTime"] as? Timestamp)?.dateValue() ?? Date(),
                    unreadCount: 0
                )
                
                DispatchQueue.main.async {
                    if !self.chats.contains(where: { $0.id == chat.id }) {
                        self.chats.append(chat)
                    }
                }
            }
        }
    }
    
    func sendMessage(eventId: String, content: String) async throws {
        guard let userId = userId,
              let userName = Auth.auth().currentUser?.displayName else { return }
        
        let message = ChatMessage(
            id: UUID().uuidString,
            eventId: eventId,
            content: content,
            senderId: userId,
            senderName: userName,
            timestamp: Date(),
            isFromCurrentUser: true
        )
        
        try await db.collection("chats")
            .document(eventId)
            .collection("messages")
            .document(message.id)
            .setData(message.dictionary)
        
        // Update last message in chat
        try await db.collection("chats")
            .document(eventId)
            .updateData([
                "lastMessage": content,
                "lastMessageTime": Timestamp(date: Date())
            ])
    }
    
    func observeMessages(eventId: String) {
        db.collection("chats")
            .document(eventId)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let messages = documents.compactMap { doc -> ChatMessage? in
                    var data = doc.data()
                    data["id"] = doc.documentID
                    data["isFromCurrentUser"] = data["senderId"] as? String == self?.userId
                    return try? Firestore.Decoder().decode(ChatMessage.self, from: data)
                }
                
                DispatchQueue.main.async {
                    self?.messages[eventId] = messages
                }
            }
    }
    
    func createChatForTicket(ticket: Ticket) async throws {
        // Check if chat already exists
        let chatDoc = try await db.collection("chats")
            .document(ticket.eventId)
            .getDocument()
        
        // Only create if it doesn't exist
        if !chatDoc.exists {
            let chatData: [String: Any] = [
                "eventName": ticket.eventName,
                "lastMessage": "Welcome to the \(ticket.eventName) chat!",
                "lastMessageTime": Timestamp(date: Date())
            ]
            
            try await db.collection("chats")
                .document(ticket.eventId)
                .setData(chatData)
        }
    }
}

// Helper extension for Firestore encoding
extension Encodable {
    var dictionary: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] } ?? [:]
    }
} 