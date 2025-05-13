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
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(title: chatTitle, showBackButton: true)
                .padding()
                .background(Color.white)
            
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.top)
                    .padding(.horizontal)
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    StyledTextField(text: $messageText, placeholder: "Type a message...")
                        .focused($isInputFocused)
                        .padding(.vertical, 8)
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.purple)
                            .padding(8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(Color.white)
            }
        }
        .background(Color(hex: 0xF9F9F9).ignoresSafeArea())
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
        isInputFocused = true
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
                    Text(formatTimestamp(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.trailing, 4)
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
                        .background(Color(hex: 0xF3F4F6))
                        .foregroundColor(.primary)
                        .cornerRadius(18)
                    Text(formatTimestamp(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
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