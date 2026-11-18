//
//  DiscoverController.swift
//  CookAI
//
//  Loads the Discover tab: recipes shared by the community (everything with
//  source == .community that moderators haven't flagged or removed), plus the
//  search/cuisine filter state for DiscoverScreen.
//

import Foundation
import Observation

@Observable
final class DiscoverController {
    enum Mode: String, CaseIterable, Identifiable {
        case recipes = "Recipes"
        case cooks = "Cooks"
        var id: String { rawValue }
    }

    private let recipeRepository: RecipeRepository
    private let authService: AuthService

    private(set) var cooks: [User] = []
    var mode: Mode = .recipes

    private(set) var recipes: [Recipe] = []
    private(set) var uploaders: [UUID: User] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var searchText = ""
    var selectedCuisine = "All"

    init(services: ServiceContainer = .shared) {
        self.recipeRepository = services.recipeRepository
        self.authService = services.authService
    }

    /// Other cooks matching the search (by name or @username), most active first.
    var shownCooks: [User] {
        let me = authService.currentUser?.id
        let others = cooks.filter { $0.id != me }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matching = query.isEmpty ? others : others.filter {
            $0.username.localizedCaseInsensitiveContains(query) || $0.displayName.localizedCaseInsensitiveContains(query)
        }
        return matching.sorted { $0.recipesCount > $1.recipesCount }
    }

    /// "All" plus every cuisine that actually appears in the community feed,
    /// so a chip never leads to an empty list.
    var cuisines: [String] {
        ["All"] + Array(Set(recipes.map(\.cuisine))).sorted()
    }

    var filteredRecipes: [Recipe] {
        let byCuisine = selectedCuisine == "All"
            ? recipes
            : recipes.filter { $0.cuisine == selectedCuisine }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return byCuisine }

        return byCuisine.filter { recipe in
            recipe.title.localizedCaseInsensitiveContains(query)
                || recipe.cuisine.localizedCaseInsensitiveContains(query)
                || (uploaders[recipe.uploaderId]?.username.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    func uploader(for recipe: Recipe) -> User? {
        uploaders[recipe.uploaderId]
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetched = try await recipeRepository.fetchCommunityRecipes()
            let ids = Array(Set(fetched.map(\.uploaderId)))
            let fetchedUploaders = try await recipeRepository.fetchUsers(ids: ids)
            recipes = fetched
            uploaders = Dictionary(fetchedUploaders.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            if !cuisines.contains(selectedCuisine) {
                selectedCuisine = "All"
            }
            if let everyone = try? await recipeRepository.fetchAllUsers() {
                cooks = everyone
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
