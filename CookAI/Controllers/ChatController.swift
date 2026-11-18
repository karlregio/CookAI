//
//  ChatController.swift
//  CookAI
//
//  One conversation: loads the messages, sends new ones, marks the other
//  person's messages as read, and quietly refreshes while the screen is open
//  so replies show up without leaving the chat.
//

import Foundation
import Observation

@Observable
final class ChatController {
    private let messageService: MessageService
    private let authService: AuthService

    let conversation: Conversation
    let other: User

    private(set) var messages: [DirectMessage] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var isSending = false
    private(set) var errorMessage: String?

    var draft = ""

    init(conversation: Conversation, other: User, services: ServiceContainer = .shared) {
        self.conversation = conversation
        self.other = other
        self.messageService = services.messageService
        self.authService = services.authService
    }

    var myId: UUID? { authService.currentUser?.id }

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    func isMine(_ message: DirectMessage) -> Bool { message.senderId == myId }

    func load() async {
        isLoading = !hasLoaded
        defer { isLoading = false; hasLoaded = true }
        await refresh()
    }

    /// Fetches the latest messages; used on open and by the screen's polling loop.
    func refresh() async {
        do {
            let latest = try await messageService.fetchMessages(conversationId: conversation.id)
            if latest != messages { messages = latest }
            if latest.contains(where: { $0.senderId != myId }) {
                try? await messageService.markRead(conversationId: conversation.id)
            }
            errorMessage = nil
        } catch {
            if !hasLoaded { errorMessage = error.localizedDescription }
        }
    }

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        isSending = true
        errorMessage = nil
        draft = ""
        defer { isSending = false }
        do {
            let sent = try await messageService.sendMessage(conversationId: conversation.id, text: text)
            if !messages.contains(where: { $0.id == sent.id }) { messages.append(sent) }
        } catch {
            draft = text
            errorMessage = error.localizedDescription
        }
    }
}
