//
//  Ingredient.swift
//  CookAI
//

import Foundation

struct Ingredient: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var quantity: String
    /// e.g. "Produce", "Pantry", "Dairy & Eggs", "Meat & Fish", "Other" — see MockData.tagCategory
    var category: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case quantity
        case category
    }
}
