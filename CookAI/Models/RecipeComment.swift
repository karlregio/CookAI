//
//  RecipeComment.swift
//  CookAI
//

import Foundation

struct RecipeComment: Codable, Identifiable, Hashable {
    var id: UUID
    var recipeId: UUID
    var authorId: UUID
    var text: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case authorId = "author_id"
        case text
        case createdAt = "created_at"
    }
}
