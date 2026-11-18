//
//  SupabaseRecipeRepository.swift
//  CookAI
//
//  RecipeRepository backed by the Supabase tables. Like/save/rating counters
//  and uploader notifications are maintained by database triggers, so this
//  class only writes the user's own rows. Row Level Security decides what
//  each user (or guest) can read.
//

import Foundation
import Supabase

final class SupabaseRecipeRepository: RecipeRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseConfig.client) {
        self.client = client
    }

    // MARK: - Row types for writes / narrow reads

    nonisolated private struct UserRecipeRow: Codable {
        let recipeId: UUID
        let userId: UUID
        enum CodingKeys: String, CodingKey {
            case recipeId = "recipe_id"
            case userId = "user_id"
        }
    }

    nonisolated private struct RatingRow: Codable {
        let recipeId: UUID
        let userId: UUID
        let stars: Int
        enum CodingKeys: String, CodingKey {
            case recipeId = "recipe_id"
            case userId = "user_id"
            case stars
        }
    }

    nonisolated private struct HistoryInsert: Encodable {
        let id: UUID
        let userId: UUID
        let recipeId: UUID
        let cookedAt: Date
        let rating: Int?
        let note: String?
        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case recipeId = "recipe_id"
            case cookedAt = "cooked_at"
            case rating
            case note
        }
    }

    nonisolated private struct CommentInsert: Encodable {
        let recipeId: UUID
        let authorId: UUID
        let text: String
        enum CodingKeys: String, CodingKey {
            case recipeId = "recipe_id"
            case authorId = "author_id"
            case text
        }
    }

    private struct RecipeInsert: Encodable {
        let id: UUID
        let title: String
        let cuisine: String
        let cookTimeMinutes: Int
        let difficulty: Difficulty
        let servings: Int
        let imageURL: String
        let source: String
        let uploaderId: UUID
        let ingredients: [Ingredient]
        let steps: [RecipeStep]
        enum CodingKeys: String, CodingKey {
            case id, title, cuisine, difficulty, servings, source, ingredients, steps
            case cookTimeMinutes = "cook_time_minutes"
            case imageURL = "image_url"
            case uploaderId = "uploader_id"
        }
    }

    // MARK: - Helpers

    private func requireUserId() throws -> UUID {
        guard let id = client.auth.currentUser?.id else {
            throw SupabaseServiceError.signInRequired
        }
        return id
    }

    @discardableResult
    private func run<T>(_ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch {
            throw SupabaseServiceError.friendly(error)
        }
    }

    // MARK: - Recipes

    func fetchLibraryRecipes() async throws -> [Recipe] {
        try await run {
            try await client.from("recipes").select()
                .eq("source", value: RecipeSource.library.rawValue)
                .eq("status", value: RecipeStatus.visible.rawValue)
                .order("created_at", ascending: true)
                .fetch()
        }
    }

    func fetchCommunityRecipes() async throws -> [Recipe] {
        try await run {
            try await client.from("recipes").select()
                .eq("source", value: RecipeSource.community.rawValue)
                .eq("status", value: RecipeStatus.visible.rawValue)
                .order("created_at", ascending: false)
                .fetch()
        }
    }

    func fetchRecipe(id: UUID) async throws -> Recipe {
        let rows: [Recipe] = try await run {
            try await client.from("recipes").select()
                .eq("id", value: id.uuidString)
                .limit(1)
                .fetch()
        }
        guard let recipe = rows.first else { throw RecipeRepositoryError.notFound }
        return recipe
    }

    func searchRecipes(query: String, cuisine: String?) async throws -> [Recipe] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return try await run {
            var request = client.from("recipes").select()
                .eq("status", value: RecipeStatus.visible.rawValue)
            if !trimmed.isEmpty {
                request = request.ilike("title", pattern: "%\(trimmed)%")
            }
            if let cuisine, cuisine != "All" {
                request = request.eq("cuisine", value: cuisine)
            }
            return try await request.order("created_at", ascending: false).fetch()
        }
    }

    func fetchInteractionState(recipeId: UUID) async throws -> RecipeInteractionState {
        guard let userId = client.auth.currentUser?.id else {
            return RecipeInteractionState(isLiked: false, isSaved: false, myRating: nil)
        }
        let recipe = recipeId.uuidString
        let user = userId.uuidString
        return try await run {
            let likes: [UserRecipeRow] = try await client.from("likes").select("recipe_id, user_id")
                .eq("recipe_id", value: recipe).eq("user_id", value: user)
                .fetch()
            let saves: [UserRecipeRow] = try await client.from("saves").select("recipe_id, user_id")
                .eq("recipe_id", value: recipe).eq("user_id", value: user)
                .fetch()
            let ratings: [RatingRow] = try await client.from("ratings").select("recipe_id, user_id, stars")
                .eq("recipe_id", value: recipe).eq("user_id", value: user)
                .fetch()
            return RecipeInteractionState(isLiked: !likes.isEmpty, isSaved: !saves.isEmpty, myRating: ratings.first?.stars)
        }
    }

    // MARK: - Save / like / rate

    @discardableResult
    func toggleSave(recipeId: UUID) async throws -> Bool {
        try await toggle(table: "saves", recipeId: recipeId)
    }

    @discardableResult
    func toggleLike(recipeId: UUID) async throws -> Bool {
        try await toggle(table: "likes", recipeId: recipeId)
    }

    /// Inserts the user's row if missing, deletes it if present. Returns the new state.
    private func toggle(table: String, recipeId: UUID) async throws -> Bool {
        let userId = try requireUserId()
        return try await run {
            let existing: [UserRecipeRow] = try await client.from(table).select("recipe_id, user_id")
                .eq("recipe_id", value: recipeId.uuidString).eq("user_id", value: userId.uuidString)
                .fetch()
            if existing.isEmpty {
                try await client.from(table)
                    .insert(UserRecipeRow(recipeId: recipeId, userId: userId))
                    .execute()
                return true
            }
            try await client.from(table).delete()
                .eq("recipe_id", value: recipeId.uuidString).eq("user_id", value: userId.uuidString)
                .execute()
            return false
        }
    }

    func fetchSavedRecipes() async throws -> [Recipe] {
        let userId = try requireUserId()
        return try await run {
            let saves: [UserRecipeRow] = try await client.from("saves").select("recipe_id, user_id")
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .fetch()
            guard !saves.isEmpty else { return [] }
            let recipes: [Recipe] = try await client.from("recipes").select()
                .in("id", values: saves.map { $0.recipeId.uuidString })
                .fetch()
            // Keep most-recently-saved first.
            let order = Dictionary(uniqueKeysWithValues: saves.enumerated().map { ($1.recipeId, $0) })
            return recipes.sorted { (order[$0.id] ?? 0) < (order[$1.id] ?? 0) }
        }
    }

    func submitRating(recipeId: UUID, stars: Int) async throws -> Recipe {
        let userId = try requireUserId()
        let clamped = max(1, min(5, stars))
        try await run {
            try await client.from("ratings")
                .upsert(RatingRow(recipeId: recipeId, userId: userId, stars: clamped), onConflict: "recipe_id,user_id")
                .execute()
        }
        return try await fetchRecipe(id: recipeId)
    }

    // MARK: - History

    func fetchHistory() async throws -> [CookHistoryEntry] {
        guard let userId = client.auth.currentUser?.id else { return [] }
        return try await run {
            try await client.from("cook_history").select("id, recipe_id, cooked_at, rating, note")
                .eq("user_id", value: userId.uuidString)
                .order("cooked_at", ascending: false)
                .fetch()
        }
    }

    func addHistoryEntry(_ entry: CookHistoryEntry) async throws {
        let userId = try requireUserId()
        try await run {
            try await client.from("cook_history").insert(HistoryInsert(
                id: entry.id, userId: userId, recipeId: entry.recipeId,
                cookedAt: entry.cookedAt, rating: entry.rating, note: entry.note
            )).execute()
        }
    }

    // MARK: - Upload

    func uploadRecipe(_ draft: RecipeDraft, photo: Data) async throws -> Recipe {
        let userId = try requireUserId()
        // The storage policy only allows writing inside a folder named after the user's id (lowercase).
        let path = "\(userId.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
        let bucket = client.storage.from("recipe-images")
        return try await run {
            _ = try await bucket.upload(path, data: photo, options: FileOptions(contentType: "image/jpeg"))
            let publicURL = try bucket.getPublicURL(path: path)
            do {
                return try await client.from("recipes")
                    .insert(RecipeInsert(
                        id: UUID(), title: draft.title, cuisine: draft.cuisine,
                        cookTimeMinutes: draft.cookTimeMinutes, difficulty: draft.difficulty,
                        servings: draft.servings, imageURL: publicURL.absoluteString,
                        source: RecipeSource.community.rawValue, uploaderId: userId,
                        ingredients: draft.ingredients, steps: draft.steps
                    ))
                    .select()
                    .single()
                    .fetch()
            } catch {
                // Don't leave an orphaned photo behind if the recipe row failed.
                _ = try? await bucket.remove(paths: [path])
                throw error
            }
        }
    }

    // MARK: - Comments

    func fetchComments(recipeId: UUID) async throws -> [RecipeComment] {
        try await run {
            try await client.from("comments").select("id, recipe_id, author_id, text, created_at")
                .eq("recipe_id", value: recipeId.uuidString)
                .order("created_at", ascending: true)
                .fetch()
        }
    }

    func addComment(recipeId: UUID, authorId: UUID, text: String) async throws -> RecipeComment {
        let userId = try requireUserId()
        return try await run {
            try await client.from("comments")
                .insert(CommentInsert(recipeId: recipeId, authorId: userId, text: text))
                .select("id, recipe_id, author_id, text, created_at")
                .single()
                .fetch()
        }
    }

    // MARK: - Users

    func fetchUsers(ids: [UUID]) async throws -> [CookAIUser] {
        let unique = Array(Set(ids))
        guard !unique.isEmpty else { return [] }
        return try await run {
            try await client.from("profiles").select()
                .in("id", values: unique.map(\.uuidString))
                .fetch()
        }
    }

    func resetSessionState() async {
        // Nothing cached locally — all state lives in the database.
    }
}
