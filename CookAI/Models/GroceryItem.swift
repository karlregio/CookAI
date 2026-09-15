//
//  GroceryItem.swift
//  CookAI
//

import Foundation

struct GroceryItem: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var recipeTitle: String
    var category: String
    var isChecked: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case recipeTitle = "recipe_title"
        case category
        case isChecked = "is_checked"
    }
}
