//
//  AdminDashboardController.swift
//  CookAI
//
//  Admin Dashboard (screen 1): live stat cards from the database, the latest
//  community submissions, and the recipes this admin has handled. Everything
//  here comes from real data; the database decides who may read it.
//

import Foundation
import Observation

@Observable
final class AdminDashboardController {
    private let recipeRepository: RecipeRepository
    private let authService: AuthService

    private(set) var stats: AdminStats?
    private(set) var recent: [Recipe] = []
    private(set) var handledByMe: [Recipe] = []
    private(set) var uploaders: [UUID: User] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(services: ServiceContainer = .shared) {
        self.recipeRepository = services.recipeRepository
        self.authService = services.authService
    }

    var isAdmin: Bool { authService.currentUser?.role == .admin }

    var todayText: String {
        Date().formatted(.dateTime.month(.abbreviated).day().year())
    }

    func uploader(for recipe: Recipe) -> User? { uploaders[recipe.uploaderId] }

    func load() async {
        guard isAdmin else {
            errorMessage = "Only admins can open the dashboard."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let loadedStats = try await recipeRepository.fetchAdminStats()
            let community = try await recipeRepository.fetchCommunityForModeration()
            let handled = try await recipeRepository.fetchMyModerationActions()

            let latest = Array(community.prefix(5))
            let mine = Array(handled.prefix(5))
            let ids = Array(Set((latest + mine).map(\.uploaderId)))
            let people = try await recipeRepository.fetchUsers(ids: ids)

            stats = loadedStats
            recent = latest
            handledByMe = mine
            uploaders = Dictionary(people.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
