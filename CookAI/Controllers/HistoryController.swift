//
//  HistoryController.swift
//  CookAI
//
//  Loads the History tab's data through RecipeRepository: cook history
//  entries, each resolved to its recipe and that recipe's uploader.
//

import Foundation
import Observation

/// A cook history entry paired with the recipe/uploader it refers to (the
/// recipe or uploader may be nil if that data has since become unavailable).
struct HistoryRow: Identifiable {
    let id: UUID
    let entry: CookHistoryEntry
    let recipe: Recipe?
    let uploader: User?
}

@Observable
final class HistoryController {
    private let recipeRepository: RecipeRepository

    private(set) var rows: [HistoryRow] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(services: ServiceContainer = .shared) {
        self.recipeRepository = services.recipeRepository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let entries = try await recipeRepository.fetchHistory()

            var recipesById: [UUID: Recipe] = [:]
            for recipeId in Set(entries.map(\.recipeId)) {
                if let recipe = try? await recipeRepository.fetchRecipe(id: recipeId) {
                    recipesById[recipeId] = recipe
                }
            }

            let uploaderIds = Array(Set(recipesById.values.map(\.uploaderId)))
            let uploaders = try await recipeRepository.fetchUsers(ids: uploaderIds)
            let uploadersById = Dictionary(uniqueKeysWithValues: uploaders.map { ($0.id, $0) })

            rows = entries.map { entry in
                let recipe = recipesById[entry.recipeId]
                let uploader = recipe.flatMap { uploadersById[$0.uploaderId] }
                return HistoryRow(id: entry.id, entry: entry, recipe: recipe, uploader: uploader)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
