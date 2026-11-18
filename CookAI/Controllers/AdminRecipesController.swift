//
//  AdminRecipesController.swift
//  CookAI
//
//  Recipe Management (screen 2): every community recipe with search (title or
//  uploader) and an All / Visible / Flagged / Removed filter, plus the quick
//  flag / remove / approve actions. Flag and remove need a reason; the
//  database enforces that and also refuses admins moderating their own recipes.
//

import Foundation
import Observation

@Observable
final class AdminRecipesController {
    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case visible = "Visible"
        case flagged = "Flagged"
        case removed = "Removed"

        var id: String { rawValue }

        var status: RecipeStatus? {
            switch self {
            case .all: return nil
            case .visible: return .visible
            case .flagged: return .flagged
            case .removed: return .removed
            }
        }
    }

    private let recipeRepository: RecipeRepository
    private let authService: AuthService

    private(set) var recipes: [Recipe] = []
    private(set) var uploaders: [UUID: User] = [:]
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var workingRecipeId: UUID?
    private(set) var errorMessage: String?
    private(set) var noticeMessage: String?

    var searchText = ""
    var selectedFilter: StatusFilter = .all

    init(services: ServiceContainer = .shared) {
        self.recipeRepository = services.recipeRepository
        self.authService = services.authService
    }

    var isAdmin: Bool { authService.currentUser?.role == .admin }

    func count(for filter: StatusFilter) -> Int {
        guard let status = filter.status else { return recipes.count }
        return recipes.filter { $0.status == status }.count
    }

    var shownRecipes: [Recipe] {
        let byStatus = selectedFilter.status.map { status in recipes.filter { $0.status == status } } ?? recipes
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return byStatus }
        return byStatus.filter { recipe in
            recipe.title.localizedCaseInsensitiveContains(query)
                || (uploaders[recipe.uploaderId]?.username.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    func uploader(for recipe: Recipe) -> User? { uploaders[recipe.uploaderId] }

    func isOwnRecipe(_ recipe: Recipe) -> Bool {
        recipe.uploaderId == authService.currentUser?.id
    }

    func load() async {
        guard isAdmin else {
            errorMessage = "Only admins can manage recipes."
            return
        }
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasLoaded = true
        }
        do {
            let community = try await recipeRepository.fetchCommunityForModeration()
            let people = try await recipeRepository.fetchUsers(ids: Array(Set(community.map(\.uploaderId))))
            recipes = community
            uploaders = Dictionary(people.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Approve (`.visible`), flag or remove. Returns true when the database accepted it.
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
            noticeMessage = AdminMessages.notice(for: status, title: recipe.title)
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
}

/// Wording shared by the admin screens.
enum AdminMessages {
    static func notice(for status: RecipeStatus, title: String) -> String {
        switch status {
        case .visible: return "“\(title)” is live again."
        case .flagged: return "“\(title)” was flagged. The uploader was notified with your reason."
        case .removed: return "“\(title)” was removed. The uploader was notified with your reason."
        }
    }
}
