//
//  ConversationsController.swift
//  CookAI
//
//  The Messages list: the signed-in user's conversations with who they're
//  with, last message, time and unread count, plus search by username.
//

import Foundation
import Observation

@Observable
final class ConversationsController {
    private let messageService: MessageService
    private let recipeRepository: RecipeRepository

    private(set) var conversations: [Conversation] = []
    private(set) var people: [UUID: User] = [:]
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    var searchText = ""

    init(services: ServiceContainer = .shared) {
        self.messageService = services.messageService
        self.recipeRepository = services.recipeRepository
    }

    var totalUnread: Int { conversations.reduce(0) { $0 + $1.unreadCount } }

    func person(in conversation: Conversation) -> User? { people[conversation.participantId] }

    var shown: [Conversation] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return conversations }
        return conversations.filter { conversation in
            guard let user = person(in: conversation) else { return false }
            return user.username.localizedCaseInsensitiveContains(query)
                || user.displayName.localizedCaseInsensitiveContains(query)
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false; hasLoaded = true }
        do {
            let loaded = try await messageService.fetchConversations()
            let users = try await recipeRepository.fetchUsers(ids: loaded.map(\.participantId))
            conversations = loaded
            people = Dictionary(users.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
