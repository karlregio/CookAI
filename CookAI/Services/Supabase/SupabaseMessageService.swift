//
//  SupabaseMessageService.swift
//  CookAI
//
//  Direct messages on the `conversations` and `messages` tables. Row-level
//  security means you only ever see conversations you're part of. A pair of
//  people has exactly one conversation; the database stores the smaller user
//  id as `user_a`, so the app orders the two ids the same way before looking
//  up or creating one.
//

import Foundation
import Supabase

final class SupabaseMessageService: MessageService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseConfig.client) {
        self.client = client
    }

    // MARK: - Wire types

    nonisolated private struct ConversationRow: Decodable {
        let id: UUID
        let userA: UUID
        let userB: UUID
        let lastMessage: String
        let lastMessageAt: Date
        enum CodingKeys: String, CodingKey {
            case id
            case userA = "user_a"
            case userB = "user_b"
            case lastMessage = "last_message"
            case lastMessageAt = "last_message_at"
        }
    }

    nonisolated private struct ConversationInsert: Encodable {
        let userA: UUID
        let userB: UUID
        enum CodingKeys: String, CodingKey {
            case userA = "user_a"
            case userB = "user_b"
        }
    }

    nonisolated private struct MessageInsert: Encodable {
        let conversationId: UUID
        let senderId: UUID
        let text: String
        enum CodingKeys: String, CodingKey {
            case conversationId = "conversation_id"
            case senderId = "sender_id"
            case text
        }
    }

    nonisolated private struct UnreadRow: Decodable {
        let conversationId: UUID
        enum CodingKeys: String, CodingKey { case conversationId = "conversation_id" }
    }

    private static let conversationColumns = "id, user_a, user_b, last_message, last_message_at"
    private static let messageColumns = "id, conversation_id, sender_id, text, sent_at"

    // MARK: - Helpers

    private func requireUserId() throws -> UUID {
        guard let id = client.auth.currentUser?.id else { throw MessageServiceError.signInRequired }
        return id
    }

    private func run<T>(_ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch {
            throw SupabaseServiceError.friendly(error)
        }
    }

    private func conversation(from row: ConversationRow, me: UUID, unread: Int) -> Conversation {
        Conversation(
            id: row.id,
            participantId: row.userA == me ? row.userB : row.userA,
            lastMessage: row.lastMessage,
            lastMessageAt: row.lastMessageAt,
            unreadCount: unread
        )
    }

    /// Unread incoming messages per conversation.
    private func unreadCounts(me: UUID) async throws -> [UUID: Int] {
        let rows: [UnreadRow] = try await client.from("messages")
            .select("conversation_id")
            .eq("is_read", value: false)
            .neq("sender_id", value: me.uuidString)
            .fetch()
        return Dictionary(grouping: rows, by: \.conversationId).mapValues(\.count)
    }

    // MARK: - MessageService

    func fetchConversations() async throws -> [Conversation] {
        guard let me = client.auth.currentUser?.id else { return [] }
        return try await run {
            let rows: [ConversationRow] = try await client.from("conversations")
                .select(Self.conversationColumns)
                .order("last_message_at", ascending: false)
                .fetch()
            let unread = try await unreadCounts(me: me)
            // A chat that was opened but never written in stays out of the list.
            return rows
                .filter { !$0.lastMessage.isEmpty || (unread[$0.id] ?? 0) > 0 }
                .map { conversation(from: $0, me: me, unread: unread[$0.id] ?? 0) }
        }
    }

    func conversation(with userId: UUID) async throws -> Conversation {
        let me = try requireUserId()
        let (a, b) = me.uuidString < userId.uuidString ? (me, userId) : (userId, me)
        return try await run {
            let existing: [ConversationRow] = try await client.from("conversations")
                .select(Self.conversationColumns)
                .eq("user_a", value: a.uuidString)
                .eq("user_b", value: b.uuidString)
                .limit(1)
                .fetch()
            if let row = existing.first {
                return conversation(from: row, me: me, unread: 0)
            }
            do {
                let created: ConversationRow = try await client.from("conversations")
                    .insert(ConversationInsert(userA: a, userB: b))
                    .select(Self.conversationColumns)
                    .single()
                    .fetch()
                return conversation(from: created, me: me, unread: 0)
            } catch {
                // The other person may have just created it: look again.
                let again: [ConversationRow] = try await client.from("conversations")
                    .select(Self.conversationColumns)
                    .eq("user_a", value: a.uuidString)
                    .eq("user_b", value: b.uuidString)
                    .limit(1)
                    .fetch()
                if let row = again.first { return conversation(from: row, me: me, unread: 0) }
                throw error
            }
        }
    }

    func fetchMessages(conversationId: UUID) async throws -> [DirectMessage] {
        try await run {
            try await client.from("messages")
                .select(Self.messageColumns)
                .eq("conversation_id", value: conversationId.uuidString)
                .order("sent_at", ascending: true)
                .fetch()
        }
    }

    func sendMessage(conversationId: UUID, text: String) async throws -> DirectMessage {
        let me = try requireUserId()
        return try await run {
            try await client.from("messages")
                .insert(MessageInsert(conversationId: conversationId, senderId: me, text: text))
                .select(Self.messageColumns)
                .single()
                .fetch()
        }
    }

    func markRead(conversationId: UUID) async throws {
        let me = try requireUserId()
        _ = try await run {
            try await client.from("messages")
                .update(["is_read": true])
                .eq("conversation_id", value: conversationId.uuidString)
                .eq("is_read", value: false)
                .neq("sender_id", value: me.uuidString)
                .execute()
        }
    }

    func fetchUnreadCount() async throws -> Int {
        guard let me = client.auth.currentUser?.id else { return 0 }
        return try await run {
            let response = try await client.from("messages")
                .select("id", head: true, count: .exact)
                .eq("is_read", value: false)
                .neq("sender_id", value: me.uuidString)
                .execute()
            return response.count ?? 0
        }
    }
}
