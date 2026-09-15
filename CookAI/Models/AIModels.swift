//
//  AIModels.swift
//  CookAI
//
//  Small supporting structs used by the AI features (recipe generation, pairing,
//  substitutions, nutrition estimation, and the cooking chat assistant).
//

import Foundation

struct NutritionEstimate: Codable, Identifiable, Hashable {
    var id: UUID
    var recipeId: UUID
    var caloriesPerServing: Int
    var proteinGrams: Int
    var carbsGrams: Int
    var fatGrams: Int
    var notes: String

    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case caloriesPerServing = "calories_per_serving"
        case proteinGrams = "protein_grams"
        case carbsGrams = "carbs_grams"
        case fatGrams = "fat_grams"
        case notes
    }
}

/// Mirrors PairingSuggestion in App.tsx (~line 1337) — a side dish/drink suggested
/// alongside a recipe, cycled from PAIRING_POOLS keyed by cuisine.
struct PairingSuggestion: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var reason: String
    var emoji: String
    /// Maps to an existing library Recipe.id when the pairing exists in the library.
    var linkedRecipeId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case reason
        case emoji
        case linkedRecipeId = "linked_recipe_id"
    }
}

/// Mirrors the SWAP_SUGGESTIONS shape in App.tsx (~line 1410) — an AI-generated
/// replacement for a single ingredient, with a note about adjustments.
struct SubstitutionSuggestion: Codable, Identifiable, Hashable {
    var id: UUID
    var originalIngredient: String
    var replacement: String
    var note: String

    enum CodingKeys: String, CodingKey {
        case id
        case originalIngredient = "original_ingredient"
        case replacement
        case note
    }
}

enum AIChatRole: String, Codable, Hashable {
    case user
    case assistant
}

struct AIChatMessage: Codable, Identifiable, Hashable {
    var id: UUID
    var role: AIChatRole
    var text: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case text
        case createdAt = "created_at"
    }
}
