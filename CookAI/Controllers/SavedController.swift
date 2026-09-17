//
//  SavedController.swift
//  CookAI
//
//  Loads the Saved tab's data through RecipeRepository. Reads/writes the
//  same saved-state as RecipeOverviewController (both go through the same
//  ServiceContainer.shared.recipeRepository instance), so saving or
//  unsaving a recipe anywhere in the app is reflected here — never a
//  separate local list.
//

import Foundation
import Observation

@Observable
final class SavedController {
    private let recipeRepository: RecipeRepository

    private(set) var recipes: [Recipe] = []
    private(set) var uploaders: [UUID: User] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(services: ServiceContainer = .shared) {
        self.recipeRepository = services.recipeRepository
    }

    func uploader(for recipe: Recipe) -> User? {
        uploaders[recipe.uploaderId]
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetchedRecipes = try await recipeRepository.fetchSavedRecipes()
            let uploaderIds = Array(Set(fetchedRecipes.map(\.uploaderId)))
            let fetchedUploaders = try await recipeRepository.fetchUsers(ids: uploaderIds)
            recipes = fetchedRecipes
            uploaders = Dictionary(uniqueKeysWithValues: fetchedUploaders.map { ($0.id, $0) })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Optimistically removes the recipe from the list, then confirms the
    /// unsave through the repository (reverting via a reload on failure).
    func unsave(_ recipe: Recipe) async {
        recipes.removeAll { $0.id == recipe.id }
        do {
            _ = try await recipeRepository.toggleSave(recipeId: recipe.id)
        } catch {
            errorMessage = error.localizedDescription
            await load()
        }
    }
}
