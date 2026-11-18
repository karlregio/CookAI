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
    /// When the account was created (nil for sample data).
    var createdAt: Date? = nil

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
        case createdAt = "created_at"
    }
}

extension User {
    /// The database hides the `email` column from everyone but the owner/admins, so
    /// profiles loaded for other people arrive without it. Missing means empty.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        username = try c.decode(String.self, forKey: .username)
        displayName = try c.decode(String.self, forKey: .displayName)
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
        role = try c.decode(UserRole.self, forKey: .role)
        avatarColorHex = try c.decode(String.self, forKey: .avatarColorHex)
        bio = try c.decode(String.self, forKey: .bio)
        isVerified = try c.decode(Bool.self, forKey: .isVerified)
        recipesCount = try c.decode(Int.self, forKey: .recipesCount)
        totalLikes = try c.decode(Int.self, forKey: .totalLikes)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
    }
}
