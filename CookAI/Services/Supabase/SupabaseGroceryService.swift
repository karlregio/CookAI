//
//  SupabaseGroceryService.swift
//  CookAI
//
//  Grocery list on the `grocery_items` table. Row-level security limits every
//  query to the signed-in user's own rows; guests do nothing here.
//

import Foundation
import Supabase

final class SupabaseGroceryService: GroceryService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseConfig.client) {
        self.client = client
    }

    nonisolated private struct GroceryRow: Encodable {
        let id: UUID
        let userId: UUID
        let name: String
        let recipeTitle: String
        let category: String
        let isChecked: Bool
        enum CodingKeys: String, CodingKey {
            case id, name, category
            case userId = "user_id"
            case recipeTitle = "recipe_title"
            case isChecked = "is_checked"
        }
    }

    private func run<T>(_ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch {
            throw SupabaseServiceError.friendly(error)
        }
    }

    func fetchItems() async throws -> [GroceryItem] {
        guard client.auth.currentUser != nil else { return [] }
        return try await run {
            try await client.from("grocery_items")
                .select("id, name, recipe_title, category, is_checked")
                .order("created_at", ascending: true)
                .fetch()
        }
    }

    func save(_ items: [GroceryItem]) async throws {
        guard let me = client.auth.currentUser?.id, !items.isEmpty else { return }
        let rows = items.map {
            GroceryRow(id: $0.id, userId: me, name: $0.name, recipeTitle: $0.recipeTitle, category: $0.category, isChecked: $0.isChecked)
        }
        _ = try await run {
            try await client.from("grocery_items").upsert(rows).execute()
        }
    }

    func setChecked(id: UUID, isChecked: Bool) async throws {
        guard client.auth.currentUser != nil else { return }
        _ = try await run {
            try await client.from("grocery_items")
                .update(["is_checked": isChecked])
                .eq("id", value: id.uuidString)
                .execute()
        }
    }

    func delete(ids: [UUID]) async throws {
        guard client.auth.currentUser != nil, !ids.isEmpty else { return }
        _ = try await run {
            try await client.from("grocery_items")
                .delete()
                .in("id", values: ids.map(\.uuidString))
                .execute()
        }
    }
}
