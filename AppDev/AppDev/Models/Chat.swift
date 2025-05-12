//
//  Chat.swift
//  AppDev
//
//  Created by Viktor Harhat on 09/05/2025.
//

import Foundation

struct ChatItem: Identifiable {
    let id = UUID()
    let iconName: String 
    let title: String
    let messagePreview: String
    let timeAgo: String
    let unreadCount: Int
}
