//
//  AppNotification.swift
//  CookAI
//

import Foundation

enum NotificationType: String, Codable, Hashable {
    case cooked
    case liked
    case commented
    case saved
    case flagged
    case removed
}

struct AppNotification: Codable, Identifiable, Hashable {
    var id: UUID
    var type: NotificationType
    var fromUserId: UUID
    var recipeId: UUID
    var recipeName: String
    var createdAt: Date
    var isRead: Bool
    var adminReason: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case fromUserId = "from_user_id"
        case recipeId = "recipe_id"
        case recipeName = "recipe_name"
        case createdAt = "created_at"
        case isRead = "is_read"
        case adminReason = "admin_reason"
    }
}
