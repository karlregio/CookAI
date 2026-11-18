//
//  RecipeOverviewController.swift
//  CookAI
//
//  Holds all state for RecipeOverviewScreen. Every action goes through
//  RecipeRepository / AIService from the ServiceContainer — never MockData
//  directly.
//

import Foundation
import Observation

/// A single ingredient row as displayed — accounts for an active swap.
struct RecipeIngredientRow: Identifiable {
    let id: UUID
    let displayText: String
    let category: String
    let isSwapped: Bool
    let swapNote: String?
}

@Observable
final class RecipeOverviewController {
    private let recipeRepository: RecipeRepository
    private let aiService: AIService

    private(set) var recipe: Recipe
    private(set) var uploader: User?
    private(set) var isLoadingUploader = false

    // Ingredients + swaps
    private(set) var checkedIngredientIds: Set<UUID> = []
    private(set) var substitutions: [UUID: SubstitutionSuggestion] = [:]
    var expandedIngredientId: UUID?
    var swapSheetIngredientId: UUID?
    var swapInputText = ""
    private(set) var swapSuggestion: SubstitutionSuggestion?
    private(set) var isRequestingSubstitution = false
    private(set) var swapErrorMessage: String?

    // Like / Save / Rating
    private(set) var isLiked = false
    private(set) var likeCount: Int
    private(set) var isSaved = false
    private(set) var isTogglingLike = false
    private(set) var isTogglingSave = false
    private(set) var likeSaveErrorMessage: String?
    var myRating = 0
    private(set) var isSubmittingRating = false
    private(set) var ratingErrorMessage: String?

    // Comments
    private(set) var comments: [RecipeComment] = []
    private(set) var commentAuthors: [UUID: User] = [:]
    var commentInput = ""
    private(set) var isLoadingComments = false
    private(set) var isPostingComment = false
    private(set) var commentsErrorMessage: String?

    // Nutrition
    private(set) var nutrition: NutritionEstimate?
    private(set) var isLoadingNutrition = false
    private(set) var nutritionErrorMessage: String?

    // Pairings
    private(set) var pairings: [PairingSuggestion] = []
    private(set) var pairingSetIndex = 0
    private(set) var isLoadingPairings = false
    private(set) var pairingsErrorMessage: String?

    // Regenerate
    private(set) var isRegenerating = false
    private(set) var regenerateErrorMessage: String?

    // Toast
    private(set) var toastMessage: String?
    private var toastTask: Task<Void, Never>?

    init(recipe: Recipe, services: ServiceContainer = .shared) {
        self.recipe = recipe
        self.likeCount = recipe.likeCount
        self.recipeRepository = services.recipeRepository
        self.aiService = services.aiService
    }

    // MARK: - Derived display state

    var ingredientRows: [RecipeIngredientRow] {
        recipe.ingredients.map { ingredient in
            if let sub = substitutions[ingredient.id] {
                return RecipeIngredientRow(id: ingredient.id, displayText: sub.replacement, category: ingredient.category, isSwapped: true, swapNote: sub.note)
            }
            let base = ingredient.quantity.isEmpty ? ingredient.name : "\(ingredient.quantity) \(ingredient.name)"
            return RecipeIngredientRow(id: ingredient.id, displayText: base, category: ingredient.category, isSwapped: false, swapNote: nil)
        }
    }

    var groceryEntries: [(name: String, category: String)] {
        ingredientRows.map { (name: $0.displayText, category: $0.category) }
    }

    // MARK: - Initial load

    func loadSecondaryContent() async {
        async let uploaderTask: Void = loadUploader()
        async let commentsTask: Void = loadComments()
        async let nutritionTask: Void = loadNutrition()
        async let pairingsTask: Void = loadPairings()
        async let interactionTask: Void = loadInteractionState()
        _ = await (uploaderTask, commentsTask, nutritionTask, pairingsTask, interactionTask)
    }

    /// Restores this user's existing like/save/rating so toggles start from the truth.
    func loadInteractionState() async {
        guard let state = try? await recipeRepository.fetchInteractionState(recipeId: recipe.id) else { return }
        isLiked = state.isLiked
        isSaved = state.isSaved
        if let rating = state.myRating {
            myRating = rating
        }
    }

    func loadUploader() async {
        isLoadingUploader = true
        defer { isLoadingUploader = false }
        do {
            uploader = try await recipeRepository.fetchUsers(ids: [recipe.uploaderId]).first
        } catch {
            uploader = nil
        }
    }

    // MARK: - Ingredients + swap

    func toggleChecked(_ ingredientId: UUID) {
        if checkedIngredientIds.contains(ingredientId) {
            checkedIngredientIds.remove(ingredientId)
        } else {
            checkedIngredientIds.insert(ingredientId)
        }
    }

    func toggleExpanded(_ ingredientId: UUID) {
        expandedIngredientId = expandedIngredientId == ingredientId ? nil : ingredientId
    }

    func beginSwap(for ingredientId: UUID) {
        swapSheetIngredientId = ingredientId
        swapInputText = ""
        swapSuggestion = nil
        swapErrorMessage = nil
    }

    func cancelSwap() {
        swapSheetIngredientId = nil
    }

    func requestSubstitution() async {
        guard let ingredientId = swapSheetIngredientId,
              let ingredient = recipe.ingredients.first(where: { $0.id == ingredientId }) else { return }
        let trimmedInput = swapInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }

        isRequestingSubstitution = true
        swapErrorMessage = nil
        defer { isRequestingSubstitution = false }
        do {
            swapSuggestion = try await aiService.suggestSubstitution(ingredient: ingredient.name, available: [trimmedInput])
        } catch {
            swapErrorMessage = error.localizedDescription
        }
    }

    func confirmSwap() {
        guard let ingredientId = swapSheetIngredientId, let suggestion = swapSuggestion else { return }
        substitutions[ingredientId] = suggestion
        swapSheetIngredientId = nil
        swapSuggestion = nil
        expandedIngredientId = nil
    }

    func undoSwap(for ingredientId: UUID) {
        substitutions.removeValue(forKey: ingredientId)
    }

    // MARK: - Like / Save / Rating

    func toggleLike() async {
        guard !isTogglingLike else { return }
        isTogglingLike = true
        likeSaveErrorMessage = nil
        defer { isTogglingLike = false }
        do {
            let newState = try await recipeRepository.toggleLike(recipeId: recipe.id)
            isLiked = newState
            likeCount += newState ? 1 : -1
        } catch {
            likeSaveErrorMessage = error.localizedDescription
        }
    }

    func toggleSave() async {
        guard !isTogglingSave else { return }
        isTogglingSave = true
        likeSaveErrorMessage = nil
        defer { isTogglingSave = false }
        do {
            isSaved = try await recipeRepository.toggleSave(recipeId: recipe.id)
        } catch {
            likeSaveErrorMessage = error.localizedDescription
        }
    }

    func submitRating() async {
        guard myRating > 0, !isSubmittingRating else { return }
        isSubmittingRating = true
        ratingErrorMessage = nil
        defer { isSubmittingRating = false }
        do {
            recipe = try await recipeRepository.submitRating(recipeId: recipe.id, stars: myRating)
        } catch {
            ratingErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Comments

    func loadComments() async {
        isLoadingComments = true
        commentsErrorMessage = nil
        defer { isLoadingComments = false }
        do {
            let fetchedComments = try await recipeRepository.fetchComments(recipeId: recipe.id)
            let authorIds = Array(Set(fetchedComments.map(\.authorId)))
            let authors = try await recipeRepository.fetchUsers(ids: authorIds)
            comments = fetchedComments
            for author in authors {
                commentAuthors[author.id] = author
            }
        } catch {
            commentsErrorMessage = error.localizedDescription
        }
    }

    /// Takes the full signed-in User (from AuthController) rather than just an
    /// id, so the newly-posted comment can be attributed and displayed
    /// immediately without a second round trip to resolve the author.
    func postComment(author: User) async {
        let trimmed = commentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isPostingComment else { return }
        isPostingComment = true
        commentsErrorMessage = nil
        defer { isPostingComment = false }
        do {
            let comment = try await recipeRepository.addComment(recipeId: recipe.id, authorId: author.id, text: trimmed)
            comments.insert(comment, at: 0)
            commentAuthors[author.id] = author
            commentInput = ""
        } catch {
            commentsErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Nutrition

    func loadNutrition() async {
        isLoadingNutrition = true
        nutritionErrorMessage = nil
        defer { isLoadingNutrition = false }
        do {
            nutrition = try await aiService.estimateNutrition(for: recipe)
        } catch {
            nutritionErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Pairings

    func loadPairings() async {
        isLoadingPairings = true
        pairingsErrorMessage = nil
        defer { isLoadingPairings = false }
        do {
            pairings = try await aiService.suggestPairings(for: recipe)
            pairingSetIndex += 1
        } catch {
            pairingsErrorMessage = error.localizedDescription
        }
    }

    func regeneratePairings() async {
        await loadPairings()
    }

    // MARK: - Regenerate with AI

    func regenerate() async {
        guard recipe.canRegenerate, !isRegenerating else { return }
        isRegenerating = true
        regenerateErrorMessage = nil
        defer { isRegenerating = false }
        do {
            let next = try await aiService.regenerateRecipe(from: recipe)
            recipe = next
            checkedIngredientIds = []
            substitutions = [:]
            expandedIngredientId = nil
            isLiked = false
            likeCount = next.likeCount
            isSaved = false
            myRating = 0
            showToast("Here's a new variation: \(next.title)")
            await loadUploader()
            await loadNutrition()
            await loadPairings()
        } catch {
            regenerateErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Toast

    func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.8))
            if !Task.isCancelled {
                toastMessage = nil
            }
        }
    }
}
