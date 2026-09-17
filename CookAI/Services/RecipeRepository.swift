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
    /// Clears per-session mutable state (saved/liked ids, history, comments,
    /// like counts) back to the seeded defaults — but never touches the
    /// underlying MockData catalog itself, which is immutable value data.
    /// Called on sign-out so a different login doesn't inherit the previous
    /// session's saved recipes, likes, or cook history.
    func resetSessionState() async
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
