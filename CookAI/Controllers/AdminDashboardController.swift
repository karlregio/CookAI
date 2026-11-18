//
//  AdminDashboardController.swift
//  CookAI
//
//  State for the admin dashboard: the community recipes grouped by moderation
//  status (live / flagged / removed), the recipes this admin has handled, and
//  the Approve / Flag / Remove actions. The database decides who may do what
//  (Row Level Security + the `moderate_recipe` function); this controller just
//  asks and shows the result or the database's error message.
//

import Foundation
import Observation

@Observable
final class AdminDashboardController {
    enum Filter: String, CaseIterable, Identifiable {
        case flagged = "Flagged"
        case live = "Live"
        case removed = "Removed"
        case mine = "My actions"

        var id: String { rawValue }
    }

    private let recipeRepository: RecipeRepository
    private let authService: AuthService

    private(set) var live: [Recipe] = []
    private(set) var flagged: [Recipe] = []
    private(set) var removed: [Recipe] = []
    private(set) var mine: [Recipe] = []
    private(set) var uploaders: [UUID: User] = [:]

    private(set) var isLoading = false
    /// The recipe whose action is in flight, so its buttons can be disabled.
    private(set) var workingRecipeId: UUID?
    private(set) var errorMessage: String?
    private(set) var noticeMessage: String?

    var selectedFilter: Filter = .flagged

    init(services: ServiceContainer = .shared) {
        self.recipeRepository = services.recipeRepository
        self.authService = services.authService
    }

    var isAdmin: Bool { authService.currentUser?.role == .admin }

    func recipes(for filter: Filter) -> [Recipe] {
        switch filter {
        case .flagged: return flagged
        case .live: return live
        case .removed: return removed
        case .mine: return mine
        }
    }

    var visibleRecipes: [Recipe] { recipes(for: selectedFilter) }

    func uploader(for recipe: Recipe) -> User? { uploaders[recipe.uploaderId] }

    /// Admins can upload like anyone else, but can't moderate their own recipes.
    func isOwnRecipe(_ recipe: Recipe) -> Bool {
        recipe.uploaderId == authService.currentUser?.id
    }

    func load() async {
        guard isAdmin else {
            errorMessage = "Only admins can open the dashboard."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let liveRecipes = try await recipeRepository.fetchModerationQueue(status: .visible)
            let flaggedRecipes = try await recipeRepository.fetchModerationQueue(status: .flagged)
            let removedRecipes = try await recipeRepository.fetchModerationQueue(status: .removed)
            let handled = try await recipeRepository.fetchMyModerationActions()

            let ids = Array(Set((liveRecipes + flaggedRecipes + removedRecipes + handled).map(\.uploaderId)))
            let people = try await recipeRepository.fetchUsers(ids: ids)

            live = liveRecipes
            flagged = flaggedRecipes
            removed = removedRecipes
            mine = handled
            uploaders = Dictionary(people.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Approve (`.visible`), flag or remove. Flag and remove need a reason.
    /// Returns true when the database accepted the change.
    @discardableResult
    func moderate(_ recipe: Recipe, to status: RecipeStatus, reason: String?) async -> Bool {
        let trimmed = reason?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if status != .visible && trimmed.isEmpty {
            errorMessage = "Please give a reason first."
            return false
        }
        workingRecipeId = recipe.id
        errorMessage = nil
        noticeMessage = nil
        defer { workingRecipeId = nil }
        do {
            _ = try await recipeRepository.moderateRecipe(id: recipe.id, status: status, reason: trimmed.isEmpty ? nil : trimmed)
            noticeMessage = Self.notice(for: status, title: recipe.title)
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func dismissMessages() {
        errorMessage = nil
        noticeMessage = nil
    }

    private static func notice(for status: RecipeStatus, title: String) -> String {
        switch status {
        case .visible: return "“\(title)” is live again."
        case .flagged: return "“\(title)” was flagged. The cook was notified with your reason."
        case .removed: return "“\(title)” was removed. The cook was notified with your reason."
        }
    }
}
