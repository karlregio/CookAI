//
//  RecipeDraft.swift
//  CookAI
//
//  A recipe the user has filled in but not yet published. The repository
//  turns it into a full Recipe (id, uploader, status, counters, photo URL).
//

import Foundation

struct RecipeDraft {
    var title: String
    var cuisine: String
    var cookTimeMinutes: Int
    var difficulty: Difficulty
    var servings: Int
    var ingredients: [Ingredient]
    var steps: [RecipeStep]
}
