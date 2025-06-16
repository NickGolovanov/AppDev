import SwiftUI
import FirebaseFirestore

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let timestamp: Date
    let isFromCurrentUser: Bool
    let senderName: String
}

struct ChatConversationView: View {
    let chatId: String
    let chatTitle: String
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var chatService: ChatService
    @State private var messageText: String = ""
    @FocusState private var isInputFocused: Bool
    
    init(chatId: String, chatTitle: String, authViewModel: AuthViewModel) {
        _chatService = StateObject(wrappedValue: ChatService(authViewModel: authViewModel))
        self.chatId = chatId
        self.chatTitle = chatTitle
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(title: chatTitle)
                .padding()
                .background(Color.white)
            
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if let messages = chatService.messages[chatId] {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(.top)
                    .padding(.horizontal)
                }
                .onChange(of: chatService.messages[chatId]?.count ?? 0) {
                    if let messages = chatService.messages[chatId],
                       let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText)
                        .padding(12)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: 0xD1D5DB))
                        )
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
        .onAppear {
            chatService.observeMessages(eventId: chatId)
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        Task {
            do {
                try await chatService.sendMessage(eventId: chatId, content: messageText)
                messageText = ""
            } catch {
                print("Error sending message: \(error)")
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
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
                // Static avatar
                Image(systemName: "person.crop.circle.fill")
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
    ChatConversationView(chatId: "preview", chatTitle: "Summer Beach Party", authViewModel: AuthViewModel())
        .environmentObject(AuthViewModel())
} 