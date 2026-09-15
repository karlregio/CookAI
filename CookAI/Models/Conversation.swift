//
//  Conversation.swift
//  CookAI
//
//  A direct-message thread between the current user and another community
//  member. Mirrors CONVERSATIONS in App.tsx.
//

import Foundation

struct Conversation: Codable, Identifiable, Hashable {
    var id: UUID
    /// The other participant in the conversation (not the current user).
    var participantId: UUID
    var lastMessage: String
    var lastMessageAt: Date
    var unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case participantId = "participant_id"
        case lastMessage = "last_message"
        case lastMessageAt = "last_message_at"
        case unreadCount = "unread_count"
    }
}
