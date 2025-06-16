import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

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
    let db = Firestore.firestore()
    @Published var chats: [ChatItem] = []
    @Published var messages: [String: [ChatMessage]] = [:] // eventId: messages
    var authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    func fetchUserChats() async throws {
        guard let user = authViewModel.currentUser, let userId = user.id else { return }

        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let joinedEventIds = userDoc.data()?["joinedEventIds"] as? [String] else {
            return
        }

        for eventId in joinedEventIds {
            let eventDoc = try await db.collection("events").document(eventId).getDocument()
            let chatDoc = try await db.collection("chats").document(eventId).getDocument()

            if chatDoc.exists, let chatData = chatDoc.data() {
                let eventName = (eventDoc.data()?["title"] as? String) ?? (chatData["eventName"] as? String) ?? "Event"
                
                let chat = ChatItem(
                    id: eventId,
                    eventId: eventId,
                    eventName: eventName,
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
        guard let user = authViewModel.currentUser else { return }
        let message = ChatMessage(
            id: UUID().uuidString,
            eventId: eventId,
            content: content,
            senderId: user.id ?? "",
            senderName: user.fullName,
            timestamp: Date(),
            isFromCurrentUser: true
        )
        try await db.collection("chats")
            .document(eventId)
            .collection("messages")
            .document(message.id)
            .setData([
                "id": message.id,
                "eventId": message.eventId,
                "content": message.content,
                "senderId": message.senderId,
                "senderName": message.senderName,
                "timestamp": Timestamp(date: message.timestamp),
                "isFromCurrentUser": message.isFromCurrentUser
            ])
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
                let currentUserId = self?.authViewModel.currentUser?.id
                let messages = documents.compactMap { doc -> ChatMessage? in
                    var data = doc.data()
                    data["id"] = doc.documentID
                    if let senderId = data["senderId"] as? String {
                        data["isFromCurrentUser"] = (senderId == currentUserId)
                    }
                    return try? Firestore.Decoder().decode(ChatMessage.self, from: data)
                }
                DispatchQueue.main.async {
                    self?.messages[eventId] = messages
                }
            }
    }
    
    func createChatForTicket(ticket: Ticket) async throws {
        let chatDoc = try await db.collection("chats")
            .document(ticket.eventId)
            .getDocument()
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

    func createChatForEvent(event: Event) async throws {
        let chatDoc = try await db.collection("chats")
            .document(event.id ?? "")
            .getDocument()
        if !chatDoc.exists {
            let chatData: [String: Any] = [
                "eventName": event.title,
                "lastMessage": "Welcome to the \(event.title) chat!",
                "lastMessageTime": Timestamp(date: Date())
            ]
            try await db.collection("chats")
                .document(event.id ?? "")
                .setData(chatData)
        }
    }
    
    func createOrganizerChat(eventId: String, eventName: String, organizerId: String) async throws {
        let chatRef = db.collection("chats").document()
        let chatId = chatRef.documentID
        
        let chatData: [String: Any] = [
            "eventId": eventId,
            "eventName": eventName,
            "organizerId": organizerId,
            "isAdminChat": true,
            "createdAt": Timestamp(date: Date())
        ]
        
        try await chatRef.setData(chatData)
        print("Organizer chat created successfully for event: \(eventName) with ID: \(chatId)")
        
        // Add an initial message to the chat
        let messageRef = chatRef.collection("messages").document()
        let messageData: [String: Any] = [
            "senderId": organizerId,
            "senderName": "System", // Or fetch organizer's name
            "text": "Welcome to the \(eventName) organizer chat!",
            "timestamp": Timestamp(date: Date())
        ]
        
        try await messageRef.setData(messageData)
        print("Initial message added to organizer chat.")
    }
}

// Helper extension for Firestore encoding
extension Encodable {
    var dictionary: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] } ?? [:]
    }
} 