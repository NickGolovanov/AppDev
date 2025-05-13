//
//  ChatView.swift
//  AppDev
//
//  Created by Viktor Harhat on 09/05/2025.
//

import SwiftUI

struct ChatView: View {
    @State private var searchText: String = ""
    
    let chats: [ChatItem] = [
        ChatItem(iconName: "bubble.left.and.bubble.right.fill", title: "Summer Beach Party", messagePreview: "Hey everyone! Don't forget to bring...", timeAgo: "10m ago", unreadCount: 3),
        ChatItem(iconName: "music.note.list", title: "EDM Night", messagePreview: "The lineup has been updated...", timeAgo: "1h ago", unreadCount: 0),
        ChatItem(iconName: "house.fill", title: "House Party @ Campus", messagePreview: "Who's bringing the snacks?", timeAgo: "2h ago", unreadCount: 1)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20){
            headerSection
            
            titleSection
            searchSection
            chatListSection
        }.padding()
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
                ForEach(chats.filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }) { chat in
                    ChatRow(chat: chat)
                }
            }
        }
    }
}


struct ChatRow: View {
    let chat: ChatItem
    
    var body: some View {
        NavigationLink(destination: ChatConversationView(chatTitle: chat.title)) {
            HStack(alignment: .center, spacing: 12) {
                // Icon (placeholder system icon)
                Image(systemName: chat.iconName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(chat.title)
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(chat.timeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: 0x6B7280))
                    }
                    Text(chat.messagePreview)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                // Unread badge
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
}

#Preview {
    ChatView()
}
