//
//  AIGenerateController.swift
//  CookAI
//
//  Drives AIGenerateScreen: the ingredient tags, dietary toggles, spice level
//  and optional cuisine; asks AIService for a recipe, then stores it through
//  RecipeRepository so the result behaves like any other recipe.
//

import Foundation
import Observation

@Observable
final class AIGenerateController {
    enum Dietary: String, CaseIterable, Identifiable {
        case vegetarian = "Vegetarian"
        case vegan = "Vegan"
        case glutenFree = "Gluten-free"
        var id: String { rawValue }
    }

    static let spiceLabels = ["Mild", "Medium", "Hot", "Extra Hot", "🔥 Inferno"]
    static let cuisineOptions = ["Filipino", "Italian", "Japanese", "Mexican", "Indian", "American", "Thai", "Korean", "French"]
    let tips = [
        "Checking what's seasonal right now...",
        "Matching your pantry to global cuisines...",
        "Asking the AI chef for inspiration...",
        "Crafting a perfect recipe just for you...",
    ]

    private let aiService: AIService
    private let recipeRepository: RecipeRepository

    var ingredientInput = ""
    private(set) var tags: [String] = []
    private(set) var dietary: Set<Dietary> = []
    var spiceLevel = 2
    /// nil means "surprise me" — any cuisine.
    var selectedCuisine: String?

    private(set) var isGenerating = false
    private(set) var tipIndex = 0
    private(set) var errorMessage: String?
    private(set) var generatedRecipe: Recipe?

    init(services: ServiceContainer = .shared) {
        self.aiService = services.aiService
        self.recipeRepository = services.recipeRepository
    }

    var spiceLabel: String {
        Self.spiceLabels[max(0, min(Self.spiceLabels.count - 1, spiceLevel))]
    }

    // MARK: - Ingredient tags

    /// Moves whatever is typed into the field into the tag list. Handles
    /// several comma-separated items pasted at once.
    func commitInput() {
        let parts = ingredientInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        for part in parts where !tags.contains(where: { $0.caseInsensitiveCompare(part) == .orderedSame }) {
            tags.append(part)
        }
        ingredientInput = ""
        errorMessage = nil
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    func toggle(_ option: Dietary) {
        if dietary.contains(option) {
            dietary.remove(option)
        } else {
            dietary.insert(option)
        }
    }

    func toggleCuisine(_ cuisine: String) {
        selectedCuisine = selectedCuisine == cuisine ? nil : cuisine
    }

    // MARK: - Generate

    func generate() async {
        guard !isGenerating else { return }
        commitInput()
        guard !tags.isEmpty else {
            errorMessage = "Add at least one ingredient so the AI has something to cook with."
            return
        }
        errorMessage = nil
        isGenerating = true
        tipIndex = 0

        let tipTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.2))
                guard let self, !Task.isCancelled else { return }
                self.tipIndex = (self.tipIndex + 1) % self.tips.count
            }
        }
        defer {
            tipTask.cancel()
            isGenerating = false
        }

        do {
            let generated = try await aiService.generateRecipe(
                ingredients: tags,
                cuisine: selectedCuisine ?? "Any",
                dietary: dietary.map(\.rawValue).sorted(),
                spiceLevel: spiceLevel
            )
            generatedRecipe = try await recipeRepository.saveGeneratedRecipe(generated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
