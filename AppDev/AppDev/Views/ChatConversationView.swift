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
                .padding()
                .background(Color.white)
            
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
            if message.isFromCurrentUser {
                Spacer(minLength: 40)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .overlay(
                            Text(formatTimestamp(message.timestamp))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                                .padding([.bottom, .trailing], 6),
                            alignment: .bottomTrailing
                        )
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.leading, 4)
                    Text(message.content)
                        .padding(12)
                        .background(Color(hex: 0x232323))
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .overlay(
                            Text(formatTimestamp(message.timestamp))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                                .padding([.bottom, .leading], 6),
                            alignment: .bottomLeading
                        )
                }
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal, 2)
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