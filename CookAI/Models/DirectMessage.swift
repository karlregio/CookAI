//
//  DirectMessage.swift
//  CookAI
//
//  A single message within a Conversation. Mirrors CHAT_HISTORY in App.tsx.
//  Distinct from AIChatMessage, which belongs to the AI cooking assistant.
//

import Foundation

struct DirectMessage: Codable, Identifiable, Hashable {
    var id: UUID
    var conversationId: UUID
    var senderId: UUID
    var text: String
    var sentAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case text
        case sentAt = "sent_at"
    }
}
