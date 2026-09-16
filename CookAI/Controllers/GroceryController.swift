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
    private(set) var items: [GroceryItem] = []

    /// Adds each entry not already present (by lowercased, trimmed name).
    /// Returns the number of items actually added (after de-duplication).
    @discardableResult
    func addItems(_ entries: [(name: String, category: String)], recipeTitle: String) -> Int {
        var existingNames = Set(items.map { $0.name.lowercased().trimmingCharacters(in: .whitespaces) })
        var addedCount = 0
        for entry in entries {
            let key = entry.name.lowercased().trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty, !existingNames.contains(key) else { continue }
            existingNames.insert(key)
            items.append(GroceryItem(id: UUID(), name: entry.name, recipeTitle: recipeTitle, category: entry.category, isChecked: false))
            addedCount += 1
        }
        return addedCount
    }

    func toggle(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isChecked.toggle()
    }

    func clearChecked() {
        items.removeAll { $0.isChecked }
    }
}
