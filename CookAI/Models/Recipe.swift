//
//  Recipe.swift
//  CookAI
//

import Foundation

enum Difficulty: String, Codable, Hashable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

enum RecipeSource: String, Codable, Hashable {
    case library
    case aiGenerated = "ai_generated"
    case community
}

enum RecipeStatus: String, Codable, Hashable {
    case visible
    case flagged
    case removed
}

struct Recipe: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var cuisine: String
    var cookTimeMinutes: Int
    var difficulty: Difficulty
    var servings: Int
    var imageURL: URL
    var source: RecipeSource
    var status: RecipeStatus
    var moderationReason: String?
    var moderatedBy: UUID?
    /// The user who uploaded this recipe. Library recipes are uploaded by the CookAI Official system user.
    var uploaderId: UUID
    var ingredients: [Ingredient]
    var steps: [RecipeStep]
    var ratingAverage: Double
    var ratingCount: Int
    var likeCount: Int
    var saveCount: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case cuisine
        case cookTimeMinutes = "cook_time_minutes"
        case difficulty
        case servings
        case imageURL = "image_url"
        case source
        case status
        case moderationReason = "moderation_reason"
        case moderatedBy = "moderated_by"
        case uploaderId = "uploader_id"
        case ingredients
        case steps
        case ratingAverage = "rating_average"
        case ratingCount = "rating_count"
        case likeCount = "like_count"
        case saveCount = "save_count"
        case createdAt = "created_at"
    }

    /// e.g. "25 min", "1 hr 10 min"
    var formattedTime: String {
        let hours = cookTimeMinutes / 60
        let minutes = cookTimeMinutes % 60
        if hours == 0 {
            return "\(minutes) min"
        }
        if minutes == 0 {
            return "\(hours) hr"
        }
        return "\(hours) hr \(minutes) min"
    }

    var canRegenerate: Bool {
        source == .aiGenerated
    }
}
