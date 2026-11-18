//
//  RecipeStep.swift
//  CookAI
//

import Foundation

enum StepAction: String, Codable, Hashable {
    case boil
    case chop
    case heat
    case saute
    case tomato
    case simmer
    case pasta
    case toss
}

extension StepAction {
    /// Picks the cook-mode illustration that best matches a free-typed step.
    static func guess(from text: String) -> StepAction {
        let s = text.lowercased()
        let table: [(StepAction, [String])] = [
            (.chop, ["chop", "dice", "slice", "mince", "cut", "peel", "grate"]),
            (.boil, ["boil"]),
            (.simmer, ["simmer", "marinate", "rest", "reduce"]),
            (.pasta, ["pasta", "noodle", "spaghetti"]),
            (.tomato, ["tomato"]),
            (.saute, ["saute", "sauté", "fry", "sear", "brown", "stir"]),
            (.heat, ["heat", "preheat", "grill", "bake", "roast", "warm"]),
            (.toss, ["toss", "mix", "serve", "plate", "combine", "garnish"]),
        ]
        return table.first { _, keys in keys.contains(where: s.contains) }?.0 ?? .saute
    }
}

struct RecipeStep: Codable, Identifiable, Hashable {
    var id: UUID
    var order: Int
    var text: String
    var timerSeconds: Int?
    var action: StepAction

    enum CodingKeys: String, CodingKey {
        case id
        case order
        case text
        case timerSeconds = "timer_seconds"
        case action
    }
}
