//
//  RootController.swift
//  CookAI
//
//  Handles the user action on the temporary build-check screen (RootView):
//  signing in against the mock AuthService and loading the mock recipe
//  library, to prove the Model/Service/View wiring works end-to-end.
//

import Foundation
import Observation

@Observable
final class RootController {
    private let authService: AuthService
    private let recipeRepository: RecipeRepository

    var statusMessage = "Tap below to verify the mock data pipeline."
    var isLoading = false

    init(services: ServiceContainer = .shared) {
        self.authService = services.authService
        self.recipeRepository = services.recipeRepository
    }

    func verifyMockDataPipeline() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await authService.signIn(email: "alex@cookai.com", password: "password")
            let recipes = try await recipeRepository.fetchLibraryRecipes()
            statusMessage = "Signed in as \(user.displayName). Loaded \(recipes.count) library recipes."
        } catch {
            statusMessage = "Something went wrong: \(error.localizedDescription)"
        }
    }
}
