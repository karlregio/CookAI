//
//  UploadRecipeController.swift
//  CookAI
//
//  Form state, validation and submit for UploadRecipeScreen. Publishes
//  through RecipeRepository, which stores the photo and the recipe row.
//

import Foundation
import Observation

@Observable
final class UploadRecipeController {
    struct IngredientRow: Identifiable {
        let id = UUID()
        var name = ""
        var quantity = ""
    }

    struct StepRow: Identifiable {
        let id = UUID()
        var text = ""
        var timerMinutes = ""
    }

    /// Quick picks only — the cuisine field accepts anything the user types.
    let suggestedCuisines = ["Filipino", "Italian", "Japanese", "Mexican", "Indian", "American", "Thai", "Korean", "Mediterranean"]

    private let recipeRepository: RecipeRepository

    var title = ""
    var cuisine = ""
    var cookTimeText = ""
    var servingsText = ""
    var difficulty: Difficulty = .easy
    var ingredientRows = [IngredientRow(), IngredientRow()]
    var stepRows = [StepRow(), StepRow()]

    private(set) var photoData: Data?
    private(set) var isPreparingPhoto = false
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?
    private(set) var publishedRecipe: Recipe?

    init(services: ServiceContainer = .shared) {
        self.recipeRepository = services.recipeRepository
    }

    // MARK: - Photo

    func setPhoto(_ rawData: Data?) {
        errorMessage = nil
        guard let rawData else {
            photoData = nil
            return
        }
        isPreparingPhoto = true
        defer { isPreparingPhoto = false }
        if let prepared = ImagePreparation.jpegData(from: rawData) {
            photoData = prepared
        } else {
            photoData = nil
            errorMessage = "That photo couldn't be read. Please pick a different one."
        }
    }

    func removePhoto() {
        photoData = nil
    }

    // MARK: - Rows

    func addIngredientRow() { ingredientRows.append(IngredientRow()) }
    func addStepRow() { stepRows.append(StepRow()) }

    func stepNumber(for id: UUID) -> Int {
        (stepRows.firstIndex { $0.id == id } ?? 0) + 1
    }

    func removeIngredientRow(_ id: UUID) {
        guard ingredientRows.count > 1 else { return }
        ingredientRows.removeAll { $0.id == id }
    }

    func removeStepRow(_ id: UUID) {
        guard stepRows.count > 1 else { return }
        stepRows.removeAll { $0.id == id }
    }

    // MARK: - Submit

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// A user-facing reason the form can't be submitted yet, or nil if it is ready.
    private func validationProblem() -> String? {
        if photoData == nil { return "Add a photo of your dish." }
        if trimmed(title).isEmpty { return "Give your recipe a name." }
        if trimmed(cuisine).isEmpty { return "Enter a cuisine, like Filipino or Thai." }
        guard let minutes = Int(trimmed(cookTimeText)), minutes > 0 else { return "Enter the cook time in minutes." }
        _ = minutes
        guard let servings = Int(trimmed(servingsText)), servings > 0 else { return "Enter how many servings it makes." }
        _ = servings
        if !ingredientRows.contains(where: { !trimmed($0.name).isEmpty }) { return "Add at least one ingredient." }
        if !stepRows.contains(where: { !trimmed($0.text).isEmpty }) { return "Add at least one step." }
        return nil
    }

    func submit() async {
        guard !isSubmitting else { return }
        errorMessage = nil
        if let problem = validationProblem() {
            errorMessage = problem
            return
        }
        guard let photoData,
              let minutes = Int(trimmed(cookTimeText)),
              let servings = Int(trimmed(servingsText)) else { return }

        let ingredients = ingredientRows.compactMap { row -> Ingredient? in
            let name = trimmed(row.name)
            guard !name.isEmpty else { return nil }
            return Ingredient(id: UUID(), name: name, quantity: trimmed(row.quantity), category: Ingredient.category(for: name))
        }

        let steps = stepRows
            .filter { !trimmed($0.text).isEmpty }
            .enumerated()
            .map { index, row -> RecipeStep in
                let text = trimmed(row.text)
                let timerSeconds = Int(trimmed(row.timerMinutes)).flatMap { $0 > 0 ? $0 * 60 : nil }
                return RecipeStep(id: UUID(), order: index + 1, text: text, timerSeconds: timerSeconds, action: StepAction.guess(from: text))
            }

        let draft = RecipeDraft(
            title: trimmed(title), cuisine: trimmed(cuisine), cookTimeMinutes: minutes,
            difficulty: difficulty, servings: servings, ingredients: ingredients, steps: steps
        )

        isSubmitting = true
        defer { isSubmitting = false }
        do {
            publishedRecipe = try await recipeRepository.uploadRecipe(draft, photo: photoData)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
