//
//  GroceryController.swift
//  CookAI
//
//  Shared app-level grocery list, injected once via the environment (see
//  RootView) so any screen — RecipeOverviewScreen today, the Grocery tab
//  itself in a later prompt — can add to and read the same list. Mirrors
//  addToGrocery() on App() in the prototype: de-duplicates by lowercased,
//  trimmed name.
//

import Foundation
import Observation

@Observable
final class GroceryController {
    private let groceryService: GroceryService

    private(set) var items: [GroceryItem] = []

    init(services: ServiceContainer = .shared) {
        self.groceryService = services.groceryService
    }

    /// Loads the signed-in user's saved list. Anything added before signing in
    /// (as a guest) is saved to the account first, so it isn't lost.
    func load() async {
        let local = items
        if !local.isEmpty { try? await groceryService.save(local) }
        guard let saved = try? await groceryService.fetchItems() else { return }
        items = saved
    }

    /// Fire-and-forget save; the list on screen is already updated.
    private func sync(_ work: @escaping () async throws -> Void) {
        Task { try? await work() }
    }

    /// Adds each entry not already present (by lowercased, trimmed name).
    /// Returns the number of items actually added (after de-duplication).
    @discardableResult
    func addItems(_ entries: [(name: String, category: String)], recipeTitle: String) -> Int {
        // Duplicates are checked within the same recipe, so every recipe's group stays complete.
        var existingNames = Set(
            items.filter { $0.recipeTitle == recipeTitle }
                .map { $0.name.lowercased().trimmingCharacters(in: .whitespaces) }
        )
        var addedCount = 0
        var added: [GroceryItem] = []
        for entry in entries {
            let key = entry.name.lowercased().trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty, !existingNames.contains(key) else { continue }
            existingNames.insert(key)
            let item = GroceryItem(id: UUID(), name: entry.name, recipeTitle: recipeTitle, category: entry.category, isChecked: false)
            items.append(item)
            added.append(item)
            addedCount += 1
        }
        if !added.isEmpty {
            let service = groceryService
            sync { try await service.save(added) }
        }
        return addedCount
    }

    /// Adds a single manually-typed item, categorized with the same
    /// keyword-matching pattern as MockData.tagCategory (duplicated here
    /// rather than called directly, so this Controller never reaches into
    /// MockData itself — only Services do).
    func addManualItem(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        addItems([(name: trimmed, category: categorize(trimmed))], recipeTitle: "Added manually")
    }

    func toggle(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isChecked.toggle()
        let service = groceryService
        let checked = items[index].isChecked
        sync { try await service.setChecked(id: id, isChecked: checked) }
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        let service = groceryService
        sync { try await service.delete(ids: [id]) }
    }

    func clearChecked() {
        let ids = items.filter(\.isChecked).map(\.id)
        items.removeAll { $0.isChecked }
        let service = groceryService
        sync { try await service.delete(ids: ids) }
    }

    /// Clears the list on screen only — called on sign-out so a different login
    /// doesn't inherit the previous session's list. The saved copy stays in the database.
    func clear() {
        items = []
    }

    private func categorize(_ ingredient: String) -> String {
        Ingredient.category(for: ingredient)
    }
}
