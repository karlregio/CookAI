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
