//
//  AdminRecipeDetailController.swift
//  CookAI
//
//  Recipe Detail, admin view (screen 3): the recipe, who submitted it (with
//  their email, which only admins can read), the reason it was flagged or
//  removed, and the Approve / Flag / Remove actions.
//

import Foundation
import Observation

@Observable
final class AdminRecipeDetailController {
    private let recipeRepository: RecipeRepository
    private let authService: AuthService

    private(set) var recipe: Recipe
    private(set) var uploader: User?
    private(set) var uploaderEmail: String?
    private(set) var isWorking = false
    private(set) var errorMessage: String?
    private(set) var noticeMessage: String?

    init(recipe: Recipe, services: ServiceContainer = .shared) {
        self.recipe = recipe
        self.recipeRepository = services.recipeRepository
        self.authService = services.authService
    }

    var isOwnRecipe: Bool { recipe.uploaderId == authService.currentUser?.id }

    var submittedText: String {
        recipe.createdAt.formatted(.dateTime.month(.abbreviated).day().year())
    }

    func load() async {
        do {
            recipe = try await recipeRepository.fetchRecipe(id: recipe.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        // Uploader details are nice to have; the recipe itself is what matters.
        uploader = try? await recipeRepository.fetchUsers(ids: [recipe.uploaderId]).first
        let emails = try? await recipeRepository.fetchUserEmails(ids: [recipe.uploaderId])
        uploaderEmail = emails?[recipe.uploaderId]
    }

    /// Approve (`.visible`), flag or remove. Returns true when the database accepted it.
    @discardableResult
    func moderate(to status: RecipeStatus, reason: String?) async -> Bool {
        let trimmed = reason?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if status != .visible && trimmed.isEmpty {
            errorMessage = "Please give a reason first."
            return false
        }
        isWorking = true
        errorMessage = nil
        noticeMessage = nil
        defer { isWorking = false }
        do {
            recipe = try await recipeRepository.moderateRecipe(id: recipe.id, status: status, reason: trimmed.isEmpty ? nil : trimmed)
            noticeMessage = AdminMessages.notice(for: status, title: recipe.title)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func dismissMessages() {
        errorMessage = nil
        noticeMessage = nil
    }
}
