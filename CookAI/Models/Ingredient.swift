//
//  Ingredient.swift
//  CookAI
//

import Foundation

struct Ingredient: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var quantity: String
    /// e.g. "Produce", "Pantry", "Dairy & Eggs", "Meat & Fish", "Other" — see MockData.tagCategory
    var category: String

    /// Keyword-based grocery category for a free-typed ingredient name.
    static func category(for name: String) -> String {
        let s = name.lowercased()
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

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case quantity
        case category
    }
}
