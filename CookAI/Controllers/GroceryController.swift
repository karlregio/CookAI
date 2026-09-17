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
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
    }

    func clearChecked() {
        items.removeAll { $0.isChecked }
    }

    /// Clears the whole list — called on sign-out so a different login
    /// doesn't inherit the previous session's grocery list.
    func clear() {
        items = []
    }

    private func categorize(_ ingredient: String) -> String {
        let s = ingredient.lowercased()
        let produce = ["tomato", "basil", "garlic", "shallot", "onion", "lemon", "lime", "ginger",
                       "chili", "chilli", "pepper", "mushroom", "spinach", "arugula", "scallion",
                       "parsley", "coriander", "cilantro", "mint", "papaya", "pineapple", "mango",
                       "apple", "avocado", "sage", "carrot", "cucumber"]
        if produce.contains(where: s.contains) { return "Produce" }

        let pantryStarch = ["pasta", "spaghetti", "rice", "flour", "panko", "bread", "cracker",
                             "ramen", "noodle", "gnocchi", "tortilla", "bun"]
        if pantryStarch.contains(where: s.contains) { return "Pantry" }

        let pantryOther = ["oil", "butter", "sugar", "salt", "vinegar", "soy sauce", "miso",
                            "fish sauce", "oyster", "sesame", "honey", "stock", "broth",
                            "coconut milk", "tahini", "achiote", "paste", "chile", "peppercorn",
                            "bay leaf", "masala", "paprika", "cumin", "turmeric"]
        if pantryOther.contains(where: s.contains) { return "Pantry" }

        let dairy = ["parmesan", "cheese", "cream", "milk", "yogurt", "egg", "feta"]
        if dairy.contains(where: s.contains) { return "Dairy & Eggs" }

        let meat = ["chicken", "beef", "pork", "salmon", "shrimp", "prawn", "lamb", "sausage",
                    "bacon", "pancetta"]
        if meat.contains(where: s.contains) { return "Meat & Fish" }

        return "Other"
    }
}
