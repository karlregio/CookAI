//
//  AdminStats.swift
//  CookAI
//
//  Live numbers for the admin dashboard cards, computed by the database
//  (`admin_stats()`), so nothing on the dashboard is made up.
//

import Foundation

struct AdminStats: Codable, Hashable {
    var totalUsers: Int
    var usersToday: Int
    var totalRecipes: Int
    var recipesToday: Int
    var recipesThisWeek: Int
    var flagged: Int

    enum CodingKeys: String, CodingKey {
        case totalUsers = "total_users"
        case usersToday = "users_today"
        case totalRecipes = "total_recipes"
        case recipesToday = "recipes_today"
        case recipesThisWeek = "recipes_this_week"
        case flagged
    }
}
