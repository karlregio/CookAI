//
//  ProfileController.swift
//  CookAI
//
//  Loads the Profile tab's derived stats through RecipeRepository. Identity
//  fields (name/email/role) come straight from AuthController in the view —
//  this controller only owns things that aren't already there: the cooked
//  count derived from real cook history, and the favorite-cuisine chip
//  selection.
//

import Foundation
import Observation

@Observable
final class ProfileController {
    private let recipeRepository: RecipeRepository

    private(set) var cookedCount = 0
    private(set) var myRecipes: [Recipe] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Ephemeral, session-only — there's no per-user preference storage yet
    /// (no Service/model backs it), so this intentionally starts empty
    /// rather than faking a pre-selected value.
    var selectedCuisines: Set<String> = []
    let allCuisines = ["Italian", "Japanese", "Filipino", "Mexican", "Indian", "American"]

    init(services: ServiceContainer = .shared) {
        self.recipeRepository = services.recipeRepository
    }

    func toggleCuisine(_ cuisine: String) {
        if selectedCuisines.contains(cuisine) {
            selectedCuisines.remove(cuisine)
        } else {
            selectedCuisines.insert(cuisine)
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let history = try await recipeRepository.fetchHistory()
            cookedCount = history.count
            myRecipes = try await recipeRepository.fetchMyRecipes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
