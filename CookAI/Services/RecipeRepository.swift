//
//  RecipeRepository.swift
//  CookAI
//
//  Protocol + mock implementation for reading/writing recipe-related data.
//  A Supabase-backed implementation will conform to the same protocol later.
//

import Foundation

protocol RecipeRepository: AnyObject {
    func fetchLibraryRecipes() async throws -> [Recipe]
    func fetchCommunityRecipes() async throws -> [Recipe]
    func fetchRecipe(id: UUID) async throws -> Recipe
    func searchRecipes(query: String, cuisine: String?) async throws -> [Recipe]
    /// Whether the signed-in user has liked/saved/rated this recipe (all false for guests).
    func fetchInteractionState(recipeId: UUID) async throws -> RecipeInteractionState
    /// Returns the new saved state (true = now saved).
    @discardableResult
    func toggleSave(recipeId: UUID) async throws -> Bool
    func fetchSavedRecipes() async throws -> [Recipe]
    /// Returns the new liked state (true = now liked).
    @discardableResult
    func toggleLike(recipeId: UUID) async throws -> Bool
    func submitRating(recipeId: UUID, stars: Int) async throws -> Recipe
    func fetchHistory() async throws -> [CookHistoryEntry]
    func addHistoryEntry(_ entry: CookHistoryEntry) async throws
    func fetchComments(recipeId: UUID) async throws -> [RecipeComment]
    func addComment(recipeId: UUID, authorId: UUID, text: String) async throws -> RecipeComment
    /// Resolves uploader/attribution profiles referenced by recipes (e.g. Recipe.uploaderId).
    func fetchUsers(ids: [UUID]) async throws -> [User]
    /// Publishes a community recipe with its photo and returns the saved recipe.
    func uploadRecipe(_ draft: RecipeDraft, photo: Data) async throws -> Recipe
    /// Stores an AI-generated recipe under the signed-in user so it can be
    /// liked, saved, rated and cooked. Guests get the recipe back unsaved.
    func saveGeneratedRecipe(_ recipe: Recipe) async throws -> Recipe
    /// Admin only (the database enforces it): every recipe (library, community, AI), whatever its status, newest first.
    func fetchRecipesForModeration() async throws -> [Recipe]
    /// Admin only: live counts for the dashboard cards.
    func fetchAdminStats() async throws -> AdminStats
    /// Every account, newest first (names and stats only; emails stay hidden).
    func fetchAllUsers() async throws -> [User]
    /// Admin only: uploaders' email addresses (hidden from everyone else).
    func fetchUserEmails(ids: [UUID]) async throws -> [UUID: String]
    /// Admin only: recipes the signed-in admin has approved, flagged or removed, newest first.
    func fetchMyModerationActions() async throws -> [Recipe]
    /// Admin only: Approve = `.visible`; `.flagged` and `.removed` need a non-empty reason.
    /// Admins can't moderate their own recipes.
    func moderateRecipe(id: UUID, status: RecipeStatus, reason: String?) async throws -> Recipe
    /// Clears per-session mutable state (saved/liked ids, history, comments,
    /// like counts) back to the seeded defaults — but never touches the
    /// underlying MockData catalog itself, which is immutable value data.
    /// Called on sign-out so a different login doesn't inherit the previous
    /// session's saved recipes, likes, or cook history.
    func resetSessionState() async
}

struct RecipeInteractionState: Hashable {
    var isLiked: Bool
    var isSaved: Bool
    var myRating: Int?
}

enum RecipeRepositoryError: LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "That recipe couldn't be found."
        }
    }
}

final class MockRecipeRepository: RecipeRepository {
    private var recipes: [Recipe]
    private var savedRecipeIds: Set<UUID> = []
    private var likedRecipeIds: Set<UUID> = []
    private var history: [CookHistoryEntry]
    private var commentsByRecipe: [UUID: [RecipeComment]]

    init() {
        recipes = MockData.allRecipes
        history = MockData.historyEntries
        commentsByRecipe = Dictionary(grouping: MockData.comments, by: \.recipeId)
    }

    private func simulateNetworkDelay() async throws {
        try await Task.sleep(for: .seconds(Double.random(in: 0.6...1.5)))
    }

    func fetchLibraryRecipes() async throws -> [Recipe] {
        try await simulateNetworkDelay()
        return recipes.filter { $0.source == .library }
    }

    func fetchCommunityRecipes() async throws -> [Recipe] {
        try await simulateNetworkDelay()
        return recipes.filter { $0.source == .community }
    }

    func fetchRecipe(id: UUID) async throws -> Recipe {
        try await simulateNetworkDelay()
        guard let recipe = recipes.first(where: { $0.id == id }) else {
            throw RecipeRepositoryError.notFound
        }
        return recipe
    }

    func searchRecipes(query: String, cuisine: String?) async throws -> [Recipe] {
        try await simulateNetworkDelay()
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return recipes.filter { recipe in
            let matchesQuery = trimmedQuery.isEmpty || recipe.title.localizedCaseInsensitiveContains(trimmedQuery)
            let matchesCuisine = cuisine == nil || cuisine == "All" || recipe.cuisine == cuisine
            return matchesQuery && matchesCuisine
        }
    }

    func fetchInteractionState(recipeId: UUID) async throws -> RecipeInteractionState {
        try await simulateNetworkDelay()
        return RecipeInteractionState(
            isLiked: likedRecipeIds.contains(recipeId),
            isSaved: savedRecipeIds.contains(recipeId),
            myRating: nil
        )
    }

    @discardableResult
    func toggleSave(recipeId: UUID) async throws -> Bool {
        try await simulateNetworkDelay()
        if savedRecipeIds.contains(recipeId) {
            savedRecipeIds.remove(recipeId)
            return false
        }
        savedRecipeIds.insert(recipeId)
        return true
    }

    func fetchSavedRecipes() async throws -> [Recipe] {
        try await simulateNetworkDelay()
        return recipes.filter { savedRecipeIds.contains($0.id) }
    }

    @discardableResult
    func toggleLike(recipeId: UUID) async throws -> Bool {
        try await simulateNetworkDelay()
        guard let index = recipes.firstIndex(where: { $0.id == recipeId }) else {
            throw RecipeRepositoryError.notFound
        }
        if likedRecipeIds.contains(recipeId) {
            likedRecipeIds.remove(recipeId)
            recipes[index].likeCount = max(0, recipes[index].likeCount - 1)
            return false
        }
        likedRecipeIds.insert(recipeId)
        recipes[index].likeCount += 1
        return true
    }

    func submitRating(recipeId: UUID, stars: Int) async throws -> Recipe {
        try await simulateNetworkDelay()
        guard let index = recipes.firstIndex(where: { $0.id == recipeId }) else {
            throw RecipeRepositoryError.notFound
        }
        let clampedStars = max(1, min(5, stars))
        let currentTotal = recipes[index].ratingAverage * Double(recipes[index].ratingCount)
        recipes[index].ratingCount += 1
        recipes[index].ratingAverage = (currentTotal + Double(clampedStars)) / Double(recipes[index].ratingCount)
        return recipes[index]
    }

    func fetchHistory() async throws -> [CookHistoryEntry] {
        try await simulateNetworkDelay()
        return history.sorted { $0.cookedAt > $1.cookedAt }
    }

    func addHistoryEntry(_ entry: CookHistoryEntry) async throws {
        try await simulateNetworkDelay()
        history.append(entry)
    }

    func uploadRecipe(_ draft: RecipeDraft, photo: Data) async throws -> Recipe {
        try await simulateNetworkDelay()
        let recipe = Recipe(
            id: UUID(), title: draft.title, cuisine: draft.cuisine, cookTimeMinutes: draft.cookTimeMinutes,
            difficulty: draft.difficulty, servings: draft.servings,
            imageURL: URL(string: "https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=400&h=300&fit=crop&auto=format")!,
            source: .community, status: .visible, moderationReason: nil, moderatedBy: nil,
            uploaderId: MockData.alexUser.id, ingredients: draft.ingredients, steps: draft.steps,
            ratingAverage: 0, ratingCount: 0, likeCount: 0, saveCount: 0, createdAt: Date()
        )
        recipes.insert(recipe, at: 0)
        return recipe
    }

    func saveGeneratedRecipe(_ recipe: Recipe) async throws -> Recipe {
        try await simulateNetworkDelay()
        if !recipes.contains(where: { $0.id == recipe.id }) {
            recipes.append(recipe)
        }
        return recipe
    }

    func fetchRecipesForModeration() async throws -> [Recipe] {
        try await simulateNetworkDelay()
        return recipes.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchAdminStats() async throws -> AdminStats {
        try await simulateNetworkDelay()
        return AdminStats(
            totalUsers: MockData.allUsers.count, usersToday: 0,
            totalRecipes: recipes.count, recipesToday: 0,
            recipesThisWeek: recipes.filter { $0.source != .library }.count,
            flagged: recipes.filter { $0.status == .flagged }.count
        )
    }

    func fetchAllUsers() async throws -> [User] {
        try await simulateNetworkDelay()
        return MockData.allUsers
    }

    func fetchUserEmails(ids: [UUID]) async throws -> [UUID: String] {
        try await simulateNetworkDelay()
        let wanted = Set(ids)
        return Dictionary(
            MockData.allUsers.filter { wanted.contains($0.id) }.map { ($0.id, $0.email) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    func fetchMyModerationActions() async throws -> [Recipe] {
        try await simulateNetworkDelay()
        return recipes.filter { $0.moderatedBy == MockData.adminUser.id }
    }

    func moderateRecipe(id: UUID, status: RecipeStatus, reason: String?) async throws -> Recipe {
        try await simulateNetworkDelay()
        guard let index = recipes.firstIndex(where: { $0.id == id }) else {
            throw RecipeRepositoryError.notFound
        }
        recipes[index].status = status
        recipes[index].moderationReason = status == .visible ? nil : reason
        recipes[index].moderatedBy = MockData.adminUser.id
        return recipes[index]
    }

    func fetchComments(recipeId: UUID) async throws -> [RecipeComment] {
        try await simulateNetworkDelay()
        return commentsByRecipe[recipeId] ?? []
    }

    func addComment(recipeId: UUID, authorId: UUID, text: String) async throws -> RecipeComment {
        try await simulateNetworkDelay()
        let comment = RecipeComment(id: UUID(), recipeId: recipeId, authorId: authorId, text: text, createdAt: Date())
        commentsByRecipe[recipeId, default: []].append(comment)
        return comment
    }

    func fetchUsers(ids: [UUID]) async throws -> [User] {
        try await simulateNetworkDelay()
        let idSet = Set(ids)
        return MockData.allUsers.filter { idSet.contains($0.id) }
    }

    func resetSessionState() async {
        recipes = MockData.allRecipes
        savedRecipeIds = []
        likedRecipeIds = []
        history = MockData.historyEntries
        commentsByRecipe = Dictionary(grouping: MockData.comments, by: \.recipeId)
    }
}
