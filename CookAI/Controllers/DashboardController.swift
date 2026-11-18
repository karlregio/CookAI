//
//  DashboardController.swift
//  CookAI
//
//  Loads the Home tab's data through RecipeRepository/NotificationService
//  and holds the search/category filter state for DashboardScreen.
//

import Foundation
import Observation

@Observable
final class DashboardController {
    private let recipeRepository: RecipeRepository
    private let notificationService: NotificationService
    private let messageService: MessageService

    private(set) var recipes: [Recipe] = []
    private(set) var uploaders: [UUID: User] = [:]
    private(set) var unreadNotificationCount = 0
    private(set) var unreadMessageCount = 0
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var searchText = ""
    var selectedCategory = "All"

    init(services: ServiceContainer = .shared) {
        self.recipeRepository = services.recipeRepository
        self.notificationService = services.notificationService
        self.messageService = services.messageService
    }

    /// Filters by cuisine category ("All" shows everything) and then by a
    /// case-insensitive match on title or cuisine.
    var filteredRecipes: [Recipe] {
        let categoryFiltered = selectedCategory == "All"
            ? recipes
            : recipes.filter { $0.cuisine == selectedCategory }

        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return categoryFiltered }

        return categoryFiltered.filter {
            $0.title.localizedCaseInsensitiveContains(trimmedQuery)
                || $0.cuisine.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    func uploader(for recipe: Recipe) -> User? {
        uploaders[recipe.uploaderId]
    }

    func loadIfNeeded() async {
        guard recipes.isEmpty else { return }
        await load()
    }

    /// Cheap refresh of just the bell badge (used when returning to the screen).
    func refreshUnreadCount() async {
        if let count = try? await notificationService.fetchUnreadCount() {
            unreadNotificationCount = count
        }
        if let count = try? await messageService.fetchUnreadCount() {
            unreadMessageCount = count
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetchedRecipes = try await recipeRepository.fetchLibraryRecipes()
            let uploaderIds = Array(Set(fetchedRecipes.map(\.uploaderId)))
            let fetchedUploaders = try await recipeRepository.fetchUsers(ids: uploaderIds)
            let fetchedUnreadCount = try await notificationService.fetchUnreadCount()

            recipes = fetchedRecipes
            uploaders = Dictionary(uniqueKeysWithValues: fetchedUploaders.map { ($0.id, $0) })
            unreadNotificationCount = fetchedUnreadCount
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func retry() async {
        await load()
    }
}
