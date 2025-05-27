//
//  ChatView.swift
//  AppDev
//
//  Created by Viktor Harhat on 09/05/2025.
//

import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var chatService: ChatService
    @State private var searchText: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    init() {
        // chatService will be initialized in .onAppear with the environment object
        _chatService = StateObject(wrappedValue: ChatService(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                titleSection
                searchSection
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack {
                        Text("Error loading chats")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if chatService.chats.isEmpty {
                    VStack {
                        Text("No chats available")
                            .font(.headline)
                        Text("Join an event to start chatting")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    chatListSection
                }
            }
            .padding()
            .onAppear {
                // Re-initialize chatService with the correct environment object
                if chatService.authViewModel !== authViewModel {
                    _chatService.wrappedValue = ChatService(authViewModel: authViewModel)
                }
                Task {
                    await loadChats()
                }
            }
        }
    }
    
    private func loadChats() async {
        do {
            try await chatService.fetchUserChats()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

extension ChatView {
    var headerSection: some View {
        HeaderView()
    }
    
    var titleSection: some View {
        Text("🎤 Event Group Chats")
            .font(.system(size: 24))
            .fontWeight(.bold)
            .foregroundColor(.primary)
    }
    
    var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(hex: 0xADAEBC))
            TextField("Search chats...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0xADAEBC))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: .infinity)
                .stroke(Color(hex: 0xE5E7EB))
                .fill(Color(hex: 0xF3F4F6))
        )
    }
    
    var chatListSection: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(chatService.chats.filter { searchText.isEmpty ? true : $0.eventName.localizedCaseInsensitiveContains(searchText) }) { chat in
                    ChatRow(chat: chat)
                }
            }
        }
    }
}

struct ChatRow: View {
    let chat: ChatItem
    
    var body: some View {
        NavigationLink(destination: ChatConversationView(chatId: chat.id, chatTitle: chat.eventName)) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: chat.iconName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(chat.eventName)
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(formatTimeAgo(chat.lastMessageTime))
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: 0x6B7280))
                    }
                    Text(chat.lastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                if chat.unreadCount > 0 {
                    Text("\(chat.unreadCount)")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.purple))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ChatView()
}
