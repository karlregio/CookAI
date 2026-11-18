//
//  MessageService.swift
//  CookAI
//
//  Direct messages between community members: the conversation list, a
//  chat's messages, sending, and read state. Supabase implementation lives in
//  Services/Supabase; the mock keeps everything in memory for previews.
//

import Foundation

protocol MessageService: AnyObject {
    /// The signed-in user's conversations, most recent first (guests get none).
    func fetchConversations() async throws -> [Conversation]
    /// Opens the conversation with another member, creating it on first use.
    func conversation(with userId: UUID) async throws -> Conversation
    func fetchMessages(conversationId: UUID) async throws -> [DirectMessage]
    func sendMessage(conversationId: UUID, text: String) async throws -> DirectMessage
    /// Marks everything the other person sent in this conversation as read.
    func markRead(conversationId: UUID) async throws
    /// Total unread messages across all conversations (for the dashboard badge).
    func fetchUnreadCount() async throws -> Int
}

enum MessageServiceError: LocalizedError {
    case signInRequired

    var errorDescription: String? {
        "Sign in to send messages."
    }
}

final class MockMessageService: MessageService {
    private var conversations: [Conversation] = []
    private var messages: [DirectMessage] = []

    func fetchConversations() async throws -> [Conversation] {
        conversations.sorted { $0.lastMessageAt > $1.lastMessageAt }
    }

    func conversation(with userId: UUID) async throws -> Conversation {
        if let existing = conversations.first(where: { $0.participantId == userId }) { return existing }
        let created = Conversation(id: UUID(), participantId: userId, lastMessage: "", lastMessageAt: Date(), unreadCount: 0)
        conversations.append(created)
        return created
    }

    func fetchMessages(conversationId: UUID) async throws -> [DirectMessage] {
        messages.filter { $0.conversationId == conversationId }.sorted { $0.sentAt < $1.sentAt }
    }

    func sendMessage(conversationId: UUID, text: String) async throws -> DirectMessage {
        let message = DirectMessage(id: UUID(), conversationId: conversationId, senderId: MockData.alexUser.id, text: text, sentAt: Date())
        messages.append(message)
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].lastMessage = text
            conversations[index].lastMessageAt = message.sentAt
        }
        return message
    }

    func markRead(conversationId: UUID) async throws {}

    func fetchUnreadCount() async throws -> Int { 0 }
}
