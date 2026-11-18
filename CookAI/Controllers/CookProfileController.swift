//
//  CookProfileController.swift
//  CookAI
//
//  Public profile of another cook: their details, stats, shared recipes, and
//  starting a conversation with them.
//

import Foundation
import Observation

@Observable
final class CookProfileController {
    private let recipeRepository: RecipeRepository
    private let messageService: MessageService
    private let authService: AuthService

    private(set) var user: User
    private(set) var recipes: [Recipe] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var isOpeningChat = false
    private(set) var errorMessage: String?

    init(user: User, services: ServiceContainer = .shared) {
        self.user = user
        self.recipeRepository = services.recipeRepository
        self.messageService = services.messageService
        self.authService = services.authService
    }

    var isMe: Bool { authService.currentUser?.id == user.id }
    var isSignedIn: Bool { authService.currentUser != nil }

    /// Likes across the cook's visible recipes.
    var totalLikes: Int { recipes.reduce(0) { $0 + $1.likeCount } }

    func load() async {
        isLoading = true
        defer { isLoading = false; hasLoaded = true }
        do {
            async let fresh = recipeRepository.fetchUsers(ids: [user.id])
            async let theirs = recipeRepository.fetchRecipes(byUploader: user.id)
            let (people, loaded) = try await (fresh, theirs)
            if let updated = people.first { user = updated }
            recipes = loaded
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Opens (or creates) the conversation with this cook.
    func openConversation() async -> Conversation? {
        guard !isOpeningChat else { return nil }
        isOpeningChat = true
        errorMessage = nil
        defer { isOpeningChat = false }
        do {
            return try await messageService.conversation(with: user.id)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
