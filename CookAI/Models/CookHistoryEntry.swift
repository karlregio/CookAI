//
//  CookHistoryEntry.swift
//  CookAI
//

import Foundation

struct CookHistoryEntry: Codable, Identifiable, Hashable {
    var id: UUID
    var recipeId: UUID
    var cookedAt: Date
    var rating: Int?
    var note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case cookedAt = "cooked_at"
        case rating
        case note
    }
}
