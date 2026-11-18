//
//  SupabaseAIService.swift
//  CookAI
//
//  AIService backed by Gemini, reached through the `ai` Supabase Edge
//  Function. The Gemini API key lives only on the server; this class sends
//  plain requests and maps the answers onto CookAI's models. Signed-in users
//  only (the function rejects guests, so we say so before making a request).
//

import Foundation
import Supabase

final class SupabaseAIService: AIService {
    private let client: SupabaseClient

    /// Shown on recipes the AI writes. Real AI dish photos can replace this later.
    private static let placeholderImageURL = URL(string: "https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=400&h=300&fit=crop&auto=format")!

    /// Nutrition doesn't change for a given recipe, so ask Gemini once per recipe per launch.
    private var nutritionCache: [UUID: NutritionEstimate] = [:]

    init(client: SupabaseClient = SupabaseConfig.client) {
        self.client = client
    }

    // MARK: - Wire types (plain values only, so they can be encoded/decoded anywhere)

    nonisolated private struct RecipeContext: Encodable {
        let title: String
        let ingredients: [String]
        let steps: [String]
    }

    nonisolated private struct StepContext: Encodable {
        let number: Int
        let text: String
    }

    nonisolated private struct ChatTurn: Encodable {
        let role: String
        let text: String
    }

    nonisolated private struct Request: Encodable {
        var action: String
        var ingredients: [String]?
        var cuisine: String?
        var dietary: [String]?
        var spiceLevel: Int?
        var title: String?
        var servings: Int?
        var ingredient: String?
        var available: [String]?
        var recipeTitle: String?
        var question: String?
        var issue: String?
        var recipe: RecipeContext?
        var step: StepContext?
        var history: [ChatTurn]?
    }

    nonisolated private struct RecipeAnswer: Decodable {
        struct Ingredient: Decodable { let name: String; let quantity: String }
        struct Step: Decodable { let text: String; let timerSeconds: Int?; let action: String }
        let title: String
        let cuisine: String
        let cookTimeMinutes: Int
        let difficulty: String
        let servings: Int
        let ingredients: [Ingredient]
        let steps: [Step]
    }

    nonisolated private struct SubstitutionAnswer: Decodable { let replacement: String; let note: String }
    nonisolated private struct NutritionAnswer: Decodable {
        let calories: Int; let protein: Int; let carbs: Int; let fat: Int; let notes: String
    }
    nonisolated private struct PairingsAnswer: Decodable {
        struct Item: Decodable { let name: String; let reason: String; let emoji: String }
        let pairings: [Item]
    }
    nonisolated private struct ReplyAnswer: Decodable { let reply: String }
    nonisolated private struct ErrorAnswer: Decodable { let error: String }

    // MARK: - Calling the function

    private func send<T: Decodable>(_ request: Request, as type: T.Type) async throws -> T {
        guard client.auth.currentUser != nil else {
            throw AIServiceError.message("Sign in to use the AI features.")
        }
        do {
            let data: Data = try await client.functions.invoke(
                "ai",
                options: FunctionInvokeOptions(body: request)
            ) { data, _ in data }
            return try JSONDecoder().decode(T.self, from: data)
        } catch let FunctionsError.httpError(_, data) {
            let message = (try? JSONDecoder().decode(ErrorAnswer.self, from: data))?.error
            throw AIServiceError.message(message ?? "The AI had a problem. Please try again.")
        } catch let error as AIServiceError {
            throw error
        } catch is DecodingError {
            throw AIServiceError.message("The AI's answer couldn't be read. Please try again.")
        } catch {
            throw SupabaseServiceError.friendly(error)
        }
    }

    private func recipeContext(_ recipe: Recipe) -> RecipeContext {
        RecipeContext(
            title: recipe.title,
            ingredients: ingredientLines(recipe),
            steps: recipe.steps.sorted { $0.order < $1.order }.map(\.text)
        )
    }

    private func ingredientLines(_ recipe: Recipe) -> [String] {
        recipe.ingredients.map { $0.quantity.isEmpty ? $0.name : "\($0.quantity) \($0.name)" }
    }

    private func makeRecipe(from answer: RecipeAnswer) -> Recipe {
        Recipe(
            id: UUID(),
            title: answer.title,
            cuisine: answer.cuisine,
            cookTimeMinutes: answer.cookTimeMinutes,
            difficulty: Difficulty(rawValue: answer.difficulty) ?? .medium,
            servings: answer.servings,
            imageURL: Self.placeholderImageURL,
            source: .aiGenerated,
            status: .visible,
            moderationReason: nil,
            moderatedBy: nil,
            uploaderId: client.auth.currentUser?.id ?? UUID(),
            ingredients: answer.ingredients.map {
                Ingredient(id: UUID(), name: $0.name, quantity: $0.quantity, category: Ingredient.category(for: $0.name))
            },
            steps: answer.steps.enumerated().map { index, step in
                RecipeStep(
                    id: UUID(),
                    order: index + 1,
                    text: step.text,
                    timerSeconds: step.timerSeconds,
                    action: StepAction(rawValue: step.action) ?? StepAction.guess(from: step.text)
                )
            },
            ratingAverage: 0,
            ratingCount: 0,
            likeCount: 0,
            saveCount: 0,
            createdAt: Date()
        )
    }

    // MARK: - AIService

    func generateRecipe(ingredients: [String], cuisine: String, dietary: [String], spiceLevel: Int) async throws -> Recipe {
        let answer = try await send(
            Request(action: "generate_recipe", ingredients: ingredients, cuisine: cuisine, dietary: dietary, spiceLevel: spiceLevel),
            as: RecipeAnswer.self
        )
        return makeRecipe(from: answer)
    }

    func regenerateRecipe(from recipe: Recipe) async throws -> Recipe {
        let answer = try await send(
            Request(action: "regenerate_recipe", ingredients: ingredientLines(recipe), cuisine: recipe.cuisine, title: recipe.title),
            as: RecipeAnswer.self
        )
        return makeRecipe(from: answer)
    }

    func suggestSubstitution(ingredient: String, available: [String]) async throws -> SubstitutionSuggestion {
        let answer = try await send(
            Request(action: "substitution", ingredient: ingredient, available: available),
            as: SubstitutionAnswer.self
        )
        return SubstitutionSuggestion(id: UUID(), originalIngredient: ingredient, replacement: answer.replacement, note: answer.note)
    }

    func estimateNutrition(for recipe: Recipe) async throws -> NutritionEstimate {
        if let cached = nutritionCache[recipe.id] { return cached }
        let answer = try await send(
            Request(action: "nutrition", ingredients: ingredientLines(recipe), title: recipe.title, servings: recipe.servings),
            as: NutritionAnswer.self
        )
        let estimate = NutritionEstimate(
            id: UUID(), recipeId: recipe.id, caloriesPerServing: answer.calories,
            proteinGrams: answer.protein, carbsGrams: answer.carbs, fatGrams: answer.fat, notes: answer.notes
        )
        nutritionCache[recipe.id] = estimate
        return estimate
    }

    func suggestPairings(for recipe: Recipe) async throws -> [PairingSuggestion] {
        let answer = try await send(
            Request(action: "pairings", cuisine: recipe.cuisine, title: recipe.title),
            as: PairingsAnswer.self
        )
        return answer.pairings.map {
            PairingSuggestion(id: UUID(), name: $0.name, reason: $0.reason, emoji: $0.emoji, linkedRecipeId: nil)
        }
    }

    func askCookingQuestion(_ question: String, recipe: Recipe, step: RecipeStep?, history: [AIChatMessage]) async throws -> String {
        // The caller already appended this question to the history; send it only once.
        var earlier = history
        if let last = earlier.last, last.role == .user, last.text == question {
            earlier.removeLast()
        }
        let answer = try await send(
            Request(
                action: "ask",
                question: question,
                recipe: recipeContext(recipe),
                step: step.map { StepContext(number: $0.order, text: $0.text) },
                history: earlier.map { ChatTurn(role: $0.role.rawValue, text: $0.text) }
            ),
            as: ReplyAnswer.self
        )
        return answer.reply
    }

    func troubleshoot(issue: String, recipe: Recipe) async throws -> String {
        let answer = try await send(
            Request(action: "troubleshoot", issue: issue, recipe: recipeContext(recipe)),
            as: ReplyAnswer.self
        )
        return answer.reply
    }
}
