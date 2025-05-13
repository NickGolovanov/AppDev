import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let timestamp: Date
    let isFromCurrentUser: Bool
    let senderName: String
}

struct ChatConversationView: View {
    let chatTitle: String
    @State private var messageText: String = ""
    @State private var messages: [Message] = [
        Message(content: "Hey everyone! Don't forget to bring snacks!", timestamp: Date().addingTimeInterval(-3600), isFromCurrentUser: false, senderName: "John"),
        Message(content: "I'll bring some chips and dip!", timestamp: Date().addingTimeInterval(-1800), isFromCurrentUser: true, senderName: "You"),
        Message(content: "I can bring drinks!", timestamp: Date().addingTimeInterval(-900), isFromCurrentUser: false, senderName: "Sarah")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(title: chatTitle, showBackButton: true)
            
            // Messages List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            // Message Input
            HStack(spacing: 12) {
                StyledTextField(text: $messageText, placeholder: "Type a message...")
                    .padding(.vertical, 8)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.purple)
                        .padding(8)
                }
            }
            .padding()
            .background(Color.white)
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let newMessage = Message(
            content: messageText,
            timestamp: Date(),
            isFromCurrentUser: true,
            senderName: "You"
        )
        messages.append(newMessage)
        messageText = ""
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isFromCurrentUser {
                // User Avatar
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if !message.isFromCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(message.content)
                    .padding(12)
                    .background(message.isFromCurrentUser ? Color.purple : Color(hex: 0xF3F4F6))
                    .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if message.isFromCurrentUser {
                Spacer()
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ChatConversationView(chatTitle: "Summer Beach Party")
} 