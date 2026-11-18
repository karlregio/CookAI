//
//  AIService.swift
//  CookAI
//
//  Protocol + mock implementation for the AI-powered features (recipe
//  generation, substitutions, nutrition, pairings, and the cooking chat
//  assistant). A real backend implementation will conform to the same
//  protocol later.
//

import Foundation

protocol AIService: AnyObject {
    func generateRecipe(ingredients: [String], cuisine: String, dietary: [String], spiceLevel: Int) async throws -> Recipe
    func regenerateRecipe(from recipe: Recipe) async throws -> Recipe
    func suggestSubstitution(ingredient: String, available: [String]) async throws -> SubstitutionSuggestion
    func estimateNutrition(for recipe: Recipe) async throws -> NutritionEstimate
    func suggestPairings(for recipe: Recipe) async throws -> [PairingSuggestion]
    func askCookingQuestion(_ question: String, recipe: Recipe, step: RecipeStep?, history: [AIChatMessage]) async throws -> String
    func troubleshoot(issue: String, recipe: Recipe) async throws -> String
}

enum AIServiceError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        }
    }
}

final class MockAIService: AIService {
    private var variationIndex = 0
    private var pairingIndexByRecipe: [UUID: Int] = [:]

    private func simulateNetworkDelay() async throws {
        try await Task.sleep(for: .seconds(Double.random(in: 0.6...1.5)))
    }

    /// Cycles through AI_VARIATIONS so every generation feels distinct, mirroring the prototype.
    func generateRecipe(ingredients: [String], cuisine: String, dietary: [String], spiceLevel: Int) async throws -> Recipe {
        try await simulateNetworkDelay()
        var recipe = MockData.aiVariations[variationIndex % MockData.aiVariations.count]
        variationIndex += 1
        recipe.id = UUID()
        recipe.createdAt = Date()
        return recipe
    }

    func regenerateRecipe(from recipe: Recipe) async throws -> Recipe {
        try await simulateNetworkDelay()
        var next = MockData.aiVariations[variationIndex % MockData.aiVariations.count]
        variationIndex += 1
        next.id = UUID()
        next.createdAt = Date()
        return next
    }

    func suggestSubstitution(ingredient: String, available: [String]) async throws -> SubstitutionSuggestion {
        try await simulateNetworkDelay()
        if let preset = MockData.swapSuggestions[ingredient] {
            return preset
        }
        let fallbackReplacement = available.first ?? "a similar ingredient you have on hand"
        return SubstitutionSuggestion(
            id: UUID(),
            originalIngredient: ingredient,
            replacement: fallbackReplacement,
            note: "Looks like a reasonable swap! Adjust seasoning to taste and keep an eye on cook time."
        )
    }

    func estimateNutrition(for recipe: Recipe) async throws -> NutritionEstimate {
        try await simulateNetworkDelay()
        let ingredientCount = recipe.ingredients.count
        return NutritionEstimate(
            id: UUID(),
            recipeId: recipe.id,
            caloriesPerServing: 320 + ingredientCount * 35,
            proteinGrams: 18 + ingredientCount,
            carbsGrams: 40 + ingredientCount * 2,
            fatGrams: 12 + ingredientCount,
            notes: "Estimate based on \(ingredientCount) ingredients across \(recipe.servings) servings. Actual values vary with brands and portion sizes."
        )
    }

    /// Cycles through the cuisine's pairing pool, mirroring "Regenerate pairing" in the prototype.
    func suggestPairings(for recipe: Recipe) async throws -> [PairingSuggestion] {
        try await simulateNetworkDelay()
        let pool = MockData.pairingPool(forCuisine: recipe.cuisine)
        let index = pairingIndexByRecipe[recipe.id, default: 0]
        pairingIndexByRecipe[recipe.id] = index + 1
        return pool[index % pool.count]
    }

    func askCookingQuestion(_ question: String, recipe: Recipe, step: RecipeStep?, history: [AIChatMessage]) async throws -> String {
        try await simulateNetworkDelay()
        let lowercasedQuestion = question.lowercased()
        if lowercasedQuestion.contains("substitut") || lowercasedQuestion.contains("swap") || lowercasedQuestion.contains("instead of") {
            return "Great question! For \(recipe.title), try a similar-textured ingredient in equal quantity, and adjust seasoning to taste."
        }
        if let step {
            return "For step \(step.order) of \(recipe.title): \(step.text) Take your time here — it's one of the steps that most affects the final result."
        }
        return "Happy to help with \(recipe.title)! Could you tell me a bit more about what you're seeing in the kitchen?"
    }

    func troubleshoot(issue: String, recipe: Recipe) async throws -> String {
        try await simulateNetworkDelay()
        return "For \(recipe.title), if you're seeing \"\(issue)\", try lowering the heat slightly and giving it a few extra minutes — most issues at this stage come down to pan temperature or timing."
    }
}
