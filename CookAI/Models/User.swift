//
//  User.swift
//  CookAI
//

import Foundation

enum UserRole: String, Codable, Hashable {
    case standard
    case admin
}

struct User: Codable, Identifiable, Hashable {
    var id: UUID
    var username: String
    var displayName: String
    var email: String
    var role: UserRole
    var avatarColorHex: String
    var bio: String
    var isVerified: Bool
    var recipesCount: Int
    var totalLikes: Int

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case email
        case role
        case avatarColorHex = "avatar_color_hex"
        case bio
        case isVerified = "is_verified"
        case recipesCount = "recipes_count"
        case totalLikes = "total_likes"
    }
}
