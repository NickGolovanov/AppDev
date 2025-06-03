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
        guard let user = authViewModel.currentUser else { return }
        let ticketsSnapshot = try await db.collection("tickets").whereField("email", isEqualTo: user.email).getDocuments()
        let eventIdToEventName: [String: String] = Dictionary(uniqueKeysWithValues: ticketsSnapshot.documents.compactMap { doc in
            guard let eventId = doc.data()["eventId"] as? String,
                  let eventName = doc.data()["eventName"] as? String else { return nil }
            return (eventId, eventName)
        })
        for (eventId, ticketEventName) in eventIdToEventName {
            let chatDoc = try await db.collection("chats").document(eventId).getDocument()
            if let chatData = chatDoc.data() {
                let firestoreEventName = chatData["eventName"] as? String ?? ""
                let eventName = firestoreEventName.isEmpty ? ticketEventName : firestoreEventName
                if firestoreEventName != ticketEventName && !ticketEventName.isEmpty {
                    try? await db.collection("chats").document(eventId).updateData(["eventName": ticketEventName])
                }
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
}

// Helper extension for Firestore encoding
extension Encodable {
    var dictionary: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] } ?? [:]
    }
} 