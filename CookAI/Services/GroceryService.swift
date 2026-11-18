//
//  GroceryService.swift
//  CookAI
//
//  Stores each signed-in user's grocery list in the database so it follows
//  them across devices. Guests keep a local-only list (the service does nothing).
//

import Foundation

protocol GroceryService: AnyObject {
    func fetchItems() async throws -> [GroceryItem]
    /// Inserts items, or updates them if they already exist (same id).
    func save(_ items: [GroceryItem]) async throws
    func setChecked(id: UUID, isChecked: Bool) async throws
    func delete(ids: [UUID]) async throws
}

/// In-memory stand-in for previews.
final class MockGroceryService: GroceryService {
    private var stored: [GroceryItem] = []

    func fetchItems() async throws -> [GroceryItem] { stored }

    func save(_ items: [GroceryItem]) async throws {
        for item in items {
            if let index = stored.firstIndex(where: { $0.id == item.id }) { stored[index] = item } else { stored.append(item) }
        }
    }

    func setChecked(id: UUID, isChecked: Bool) async throws {
        if let index = stored.firstIndex(where: { $0.id == id }) { stored[index].isChecked = isChecked }
    }

    func delete(ids: [UUID]) async throws {
        stored.removeAll { ids.contains($0.id) }
    }
}
