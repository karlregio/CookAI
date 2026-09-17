//
//  MockData.swift
//  CookAI
//
//  Ported from the React prototype (src/App.tsx lines ~46–1600): RECIPES,
//  COOK_STEPS, HISTORY_ITEMS, COMMUNITY_RECIPES, COMMUNITY_USERS,
//  ADMIN_SUBMISSIONS, CONVERSATIONS, CHAT_HISTORY, AI_MESSAGES, SEED_RATINGS,
//  AI_VARIATIONS, PAIRING_POOLS, SWAP_SUGGESTIONS, SEED_NOTIFICATIONS,
//  SEED_COMMENTS.
//
//  Fix applied vs. the prototype: in App.tsx every recipe reused the same
//  Spaghetti Pomodoro COOK_STEPS/ingredients regardless of which recipe was
//  opened. Here each library recipe gets its own realistic ingredients and
//  steps, and only Spaghetti Pomodoro keeps the original 8-step COOK_STEPS.
//  Notifications/comments also now point at real recipe ids (the prototype's
//  SEED_NOTIFICATIONS referenced "r1"/"r3" ids and titles like "Miso Ramen"
//  that don't correspond to any actual recipe).
//

import Foundation

// MARK: - Fixed ID helper

/// Deterministic UUID generator so mock records keep stable ids across app
/// launches (recipes, users, notifications, etc. reference each other by id).
private func uid(_ n: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", n))!
}

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
    Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

private func ing(_ name: String, _ quantity: String) -> Ingredient {
    Ingredient(id: UUID(), name: name, quantity: quantity, category: MockData.tagCategory(name))
}

private func step(_ order: Int, _ text: String, timer: Int? = nil, action: StepAction) -> RecipeStep {
    RecipeStep(id: UUID(), order: order, text: text, timerSeconds: timer, action: action)
}

enum MockData {

    // MARK: - Category tagger (ports tagCategory() from App.tsx ~line 386)

    /// Heuristic category tagger — keeps ingredient lists feeling smart without a backend.
    static func tagCategory(_ ingredient: String) -> String {
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

    // MARK: - Users

    static let systemUser = User(
        id: uid(1),
        username: "cookai_official",
        displayName: "CookAI Official",
        email: "official@cookai.com",
        role: .admin,
        avatarColorHex: "#8A9B6E",
        bio: "The official CookAI recipe library — curated, tested, and ready to cook.",
        isVerified: true,
        recipesCount: 6,
        totalLikes: 4820
    )

    static let alexUser = User(
        id: uid(2),
        username: "alex",
        displayName: "Alex",
        email: "alex@cookai.com",
        role: .standard,
        avatarColorHex: "#D9713C",
        bio: "Home cook learning one recipe at a time.",
        isVerified: false,
        recipesCount: 0,
        totalLikes: 0
    )

    static let adminUser = User(
        id: uid(3),
        username: "admin",
        displayName: "Admin",
        email: "admin@cookai.com",
        role: .admin,
        avatarColorHex: "#5C4F4A",
        bio: "CookAI platform administrator.",
        isVerified: true,
        recipesCount: 0,
        totalLikes: 0
    )

    static let naomiCooks = User(id: uid(11), username: "naomi_cooks", displayName: "naomi_cooks", email: "naomi@example.com", role: .standard, avatarColorHex: "#8A9B6E", bio: "Home cook obsessed with Japanese flavours & seasonal produce. Tokyo → London.", isVerified: false, recipesCount: 14, totalLikes: 1840)
    static let grillMaestro = User(id: uid(12), username: "grill_maestro", displayName: "grill_maestro", email: "grillmaestro@example.com", role: .standard, avatarColorHex: "#D9713C", bio: "Outdoor grilling enthusiast. If it doesn't have char marks, did you even cook it?", isVerified: false, recipesCount: 9, totalLikes: 963)
    static let bangkokKitchen = User(id: uid(13), username: "bangkok_kitchen", displayName: "bangkok_kitchen", email: "bkkitchen@example.com", role: .standard, avatarColorHex: "#B85A28", bio: "Bringing street-food energy to your home kitchen. Always spicy.", isVerified: false, recipesCount: 22, totalLikes: 2310)
    static let pastaPerfecta = User(id: uid(14), username: "pasta_perfecta", displayName: "pasta_perfecta", email: "pastaperfecta@example.com", role: .standard, avatarColorHex: "#5C4F4A", bio: "Nonnas of Italy, I salute you. Pasta every day, twice on Sundays.", isVerified: false, recipesCount: 31, totalLikes: 5120)
    static let spiceRoute = User(id: uid(15), username: "spice_route", displayName: "spice_route", email: "spiceroute@example.com", role: .standard, avatarColorHex: "#8A9B6E", bio: "Tracing the ancient spice routes one dish at a time. Vegetarian-friendly.", isVerified: false, recipesCount: 18, totalLikes: 2670)
    static let weekendGriller = User(id: uid(16), username: "weekend_griller", displayName: "weekend_griller", email: "weekendgriller@example.com", role: .standard, avatarColorHex: "#D9713C", bio: "Burgers, BBQ, and backyard vibes. Weekend warrior chef.", isVerified: false, recipesCount: 7, totalLikes: 1200)

    static let chefMarco = User(id: uid(21), username: "chef_marco", displayName: "chef_marco", email: "marco@example.com", role: .standard, avatarColorHex: "#D9713C", bio: "Weeknight pasta enthusiast.", isVerified: false, recipesCount: 3, totalLikes: 210)
    static let yukiEats = User(id: uid(22), username: "yuki_eats", displayName: "yuki_eats", email: "yuki@example.com", role: .standard, avatarColorHex: "#9C8F8A", bio: "Ramen every Sunday.", isVerified: false, recipesCount: 1, totalLikes: 48)
    static let amaraKitchen = User(id: uid(23), username: "amara_kitchen", displayName: "amara_kitchen", email: "amara@example.com", role: .standard, avatarColorHex: "#B3C49A", bio: "Cooking my way through every cuisine.", isVerified: false, recipesCount: 5, totalLikes: 302)
    static let phoebeBakes = User(id: uid(24), username: "phoebe_bakes", displayName: "phoebe_bakes", email: "phoebe@example.com", role: .standard, avatarColorHex: "#D9713C", bio: "Mostly desserts, occasionally dinner.", isVerified: false, recipesCount: 9, totalLikes: 640)

    /// All community users, keyed by username — mirrors COMMUNITY_USERS.
    static let communityUsers: [User] = [naomiCooks, grillMaestro, bangkokKitchen, pastaPerfecta, spiceRoute, weekendGriller]

    /// Every mock user, for lookup by id.
    static let allUsers: [User] = [systemUser, alexUser, adminUser] + communityUsers + [chefMarco, yukiEats, amaraKitchen, phoebeBakes]

    static func user(id: UUID) -> User? {
        allUsers.first { $0.id == id }
    }

    // MARK: - Library recipes (RECIPES + SEED_RATINGS)

    static let spaghettiPomodoro = Recipe(
        id: uid(101),
        title: "Spaghetti Pomodoro",
        cuisine: "Italian",
        cookTimeMinutes: 25,
        difficulty: .easy,
        servings: 2,
        imageURL: URL(string: "https://images.unsplash.com/photo-1713561058969-793049b01712?w=400&h=300&fit=crop&auto=format")!,
        source: .library,
        status: .visible,
        moderationReason: nil,
        moderatedBy: nil,
        uploaderId: systemUser.id,
        ingredients: [
            ing("Spaghetti", "400g"),
            ing("San Marzano tomatoes", "2 cans (400g each)"),
            ing("Garlic", "4 cloves, minced"),
            ing("Shallot", "1 small, finely diced"),
            ing("Extra-virgin olive oil", "3 tbsp"),
            ing("Sugar", "1 tsp"),
            ing("Fresh basil leaves, a handful", ""),
            ing("Salt and black pepper, to taste", ""),
            ing("Parmesan cheese, for serving", ""),
        ],
        steps: [
            step(1, "Bring a large pot of salted water to a boil. Use about 1 tablespoon of salt per liter of water.", action: .boil),
            step(2, "Finely dice 4 cloves of garlic and 1 small shallot. Set aside in a small bowl.", action: .chop),
            step(3, "Heat 3 tablespoons of olive oil in a large skillet over medium heat until shimmering.", action: .heat),
            step(4, "Add garlic and shallots to the pan. Sauté until fragrant and golden, stirring occasionally.", timer: 180, action: .saute),
            step(5, "Add a 400g can of San Marzano tomatoes, crushing them by hand as you add them to the pan.", action: .tomato),
            step(6, "Season with salt, pepper, and a pinch of sugar. Let the sauce simmer and reduce.", timer: 300, action: .simmer),
            step(7, "Add pasta to boiling water and cook until al dente, 1 minute less than package directions.", timer: 480, action: .pasta),
            step(8, "Reserve ½ cup pasta water, drain pasta, and toss with sauce over high heat. Serve immediately.", action: .toss),
        ],
        ratingAverage: 4.7,
        ratingCount: 214,
        likeCount: 248,
        saveCount: 132,
        createdAt: date(2026, 8, 1)
    )

    static let tonkotsuRamen = Recipe(
        id: uid(102),
        title: "Tonkotsu Ramen",
        cuisine: "Japanese",
        cookTimeMinutes: 45,
        difficulty: .medium,
        servings: 1,
        imageURL: URL(string: "https://images.unsplash.com/photo-1612927601601-6638404737ce?w=400&h=300&fit=crop&auto=format")!,
        source: .library,
        status: .visible,
        moderationReason: nil,
        moderatedBy: nil,
        uploaderId: systemUser.id,
        ingredients: [
            ing("Ramen noodles", "1 fresh pack"),
            ing("Pork tonkotsu broth base", "500ml"),
            ing("Chicken stock", "250ml"),
            ing("Chashu pork belly, sliced", "4 slices"),
            ing("Soft-boiled egg", "1"),
            ing("Garlic", "2 cloves, minced"),
            ing("Green onions, sliced, to garnish", ""),
            ing("Nori sheet", "1"),
            ing("Sesame oil", "1 tsp"),
            ing("Soy sauce", "1 tbsp"),
        ],
        steps: [
            step(1, "Slice green onions and prepare toppings: chashu pork, soft-boiled egg, and nori.", action: .chop),
            step(2, "Warm the tonkotsu broth and chicken stock together in a pot over medium heat.", action: .heat),
            step(3, "In a small pan, sauté the minced garlic in sesame oil until fragrant.", timer: 120, action: .saute),
            step(4, "Stir the garlic oil and soy sauce into the broth. Simmer gently to combine the flavors.", timer: 300, action: .simmer),
            step(5, "Cook the ramen noodles in boiling water for 60–90 seconds, then drain well.", timer: 90, action: .pasta),
            step(6, "If not prepared ahead, bring a separate pot of water to a boil to soft-boil the egg.", timer: 420, action: .boil),
            step(7, "Place noodles in a bowl, ladle over the hot broth, and arrange chashu, egg, nori, and green onions on top.", action: .toss),
        ],
        ratingAverage: 4.4,
        ratingCount: 98,
        likeCount: 176,
        saveCount: 94,
        createdAt: date(2026, 8, 3)
    )

    static let streetTacosAlPastor = Recipe(
        id: uid(103),
        title: "Street Tacos Al Pastor",
        cuisine: "Mexican",
        cookTimeMinutes: 35,
        difficulty: .medium,
        servings: 4,
        imageURL: URL(string: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400&h=300&fit=crop&auto=format")!,
        source: .library,
        status: .visible,
        moderationReason: nil,
        moderatedBy: nil,
        uploaderId: systemUser.id,
        ingredients: [
            ing("Pork shoulder, thinly sliced", "700g"),
            ing("Dried guajillo chiles", "3"),
            ing("Pineapple, diced", "½"),
            ing("White onion, diced", "1"),
            ing("Garlic", "4 cloves"),
            ing("Achiote paste", "2 tbsp"),
            ing("Apple cider vinegar", "2 tbsp"),
            ing("Corn tortillas", "12 small"),
            ing("Fresh cilantro, chopped, a handful", ""),
            ing("Lime wedges, to serve", ""),
        ],
        steps: [
            step(1, "Dice the onion, pineapple, and garlic. Chop cilantro for garnish.", action: .chop),
            step(2, "Toast the dried guajillo chiles in a dry pan over medium heat until fragrant, about 1 minute.", timer: 60, action: .heat),
            step(3, "Blend the toasted chiles with achiote paste, vinegar, garlic, and a splash of water into a smooth marinade.", action: .saute),
            step(4, "Marinate the sliced pork in the achiote mixture for at least 20 minutes.", timer: 1200, action: .simmer),
            step(5, "Cook the marinated pork on a hot skillet or griddle until charred and cooked through, 8–10 minutes.", timer: 600, action: .heat),
            step(6, "Sauté the diced pineapple in the same pan until lightly caramelized.", timer: 180, action: .saute),
            step(7, "Warm the tortillas, then fill with chopped pork, pineapple, onion, and cilantro. Serve with lime.", action: .toss),
        ],
        ratingAverage: 4.2,
        ratingCount: 76,
        likeCount: 121,
        saveCount: 58,
        createdAt: date(2026, 8, 5)
    )

    static let chickenAdobo = Recipe(
        id: uid(104),
        title: "Chicken Adobo",
        cuisine: "Filipino",
        cookTimeMinutes: 50,
        difficulty: .easy,
        servings: 4,
        imageURL: URL(string: "https://images.unsplash.com/photo-1636647511603-f46efb36c327?w=400&h=300&fit=crop&auto=format")!,
        source: .library,
        status: .visible,
        moderationReason: nil,
        moderatedBy: nil,
        uploaderId: systemUser.id,
        ingredients: [
            ing("Chicken thighs and legs", "1kg"),
            ing("Soy sauce", "120ml"),
            ing("White vinegar", "80ml"),
            ing("Garlic, crushed", "6 cloves"),
            ing("Bay leaves", "2"),
            ing("Black peppercorns, whole", "1 tsp"),
            ing("Brown sugar", "1 tbsp"),
            ing("Water", "250ml"),
            ing("Cooking oil", "1 tbsp"),
        ],
        steps: [
            step(1, "Crush the garlic cloves and set aside with the bay leaves and peppercorns.", action: .chop),
            step(2, "Combine chicken, soy sauce, vinegar, garlic, bay leaves, and peppercorns in a bowl. Marinate 15 minutes.", timer: 900, action: .simmer),
            step(3, "Heat oil in a large pot over medium-high heat.", action: .heat),
            step(4, "Sear the marinated chicken pieces until lightly browned on all sides, about 5 minutes.", timer: 300, action: .saute),
            step(5, "Pour in the marinade and water, then bring to a boil.", action: .boil),
            step(6, "Reduce heat and simmer uncovered until the chicken is tender and the sauce has reduced, about 25 minutes.", timer: 1500, action: .simmer),
            step(7, "Stir in the brown sugar during the last 5 minutes and toss the chicken to coat in the glossy sauce.", timer: 300, action: .toss),
        ],
        ratingAverage: 4.8,
        ratingCount: 183,
        likeCount: 302,
        saveCount: 210,
        createdAt: date(2026, 8, 7)
    )

    static let butterChicken = Recipe(
        id: uid(105),
        title: "Butter Chicken",
        cuisine: "Indian",
        cookTimeMinutes: 40,
        difficulty: .medium,
        servings: 3,
        imageURL: URL(string: "https://images.unsplash.com/photo-1625631980741-33a7752108f4?w=400&h=300&fit=crop&auto=format")!,
        source: .library,
        status: .visible,
        moderationReason: nil,
        moderatedBy: nil,
        uploaderId: systemUser.id,
        ingredients: [
            ing("Chicken thighs, diced", "600g"),
            ing("Plain yogurt", "100g"),
            ing("Garlic, minced", "4 cloves"),
            ing("Ginger, grated", "1 tbsp"),
            ing("Garam masala", "2 tsp"),
            ing("Tomato puree", "400g"),
            ing("Heavy cream", "120ml"),
            ing("Butter", "3 tbsp"),
            ing("Kashmiri chili powder", "1 tsp"),
            ing("Basmati rice, to serve", ""),
        ],
        steps: [
            step(1, "Mince the garlic and grate the ginger.", action: .chop),
            step(2, "Marinate the diced chicken in yogurt, half the garlic and ginger, and 1 tsp garam masala for at least 20 minutes.", timer: 1200, action: .simmer),
            step(3, "Heat 1 tablespoon of butter in a pan over medium-high heat.", action: .heat),
            step(4, "Cook the marinated chicken until browned and mostly cooked through, about 6 minutes.", timer: 360, action: .saute),
            step(5, "Add the remaining garlic, ginger, chili powder, and tomato puree to the pan.", action: .tomato),
            step(6, "Simmer the sauce for 10 minutes, then stir in the cream and remaining butter.", timer: 600, action: .simmer),
            step(7, "Return the chicken to the sauce and toss to coat. Simmer 5 more minutes and serve over basmati rice.", timer: 300, action: .toss),
        ],
        ratingAverage: 4.5,
        ratingCount: 127,
        likeCount: 218,
        saveCount: 143,
        createdAt: date(2026, 8, 9)
    )

    static let classicCheeseburger = Recipe(
        id: uid(106),
        title: "Classic Cheeseburger",
        cuisine: "American",
        cookTimeMinutes: 20,
        difficulty: .easy,
        servings: 2,
        imageURL: URL(string: "https://images.unsplash.com/photo-1636647511729-6703539ba71f?w=400&h=300&fit=crop&auto=format")!,
        source: .library,
        status: .visible,
        moderationReason: nil,
        moderatedBy: nil,
        uploaderId: systemUser.id,
        ingredients: [
            ing("Ground beef 80/20", "300g"),
            ing("Cheddar cheese slices", "2"),
            ing("Burger buns, toasted", "2"),
            ing("Lettuce", "2 leaves"),
            ing("Tomato, sliced", "2 slices"),
            ing("Red onion, thinly sliced, a few slices", ""),
            ing("Pickles, sliced, to taste", ""),
            ing("Ketchup and mustard, to taste", ""),
            ing("Salt and black pepper, to taste", ""),
        ],
        steps: [
            step(1, "Slice the tomato and onion, and prepare the lettuce and pickles.", action: .chop),
            step(2, "Divide the beef into 2 loose balls, then heat a skillet over high heat until smoking.", action: .heat),
            step(3, "Place the beef balls in the pan and immediately smash flat with a spatula. Season with salt and pepper.", timer: 120, action: .saute),
            step(4, "Flip the patties, top each with a slice of cheddar, and cook 1 more minute until melted.", timer: 60, action: .heat),
            step(5, "Toast the buns lightly, then assemble with the patty, lettuce, tomato, onion, and pickles.", action: .toss),
        ],
        ratingAverage: 4.1,
        ratingCount: 61,
        likeCount: 97,
        saveCount: 40,
        createdAt: date(2026, 8, 11)
    )

    static let libraryRecipes: [Recipe] = [
        spaghettiPomodoro, tonkotsuRamen, streetTacosAlPastor, chickenAdobo, butterChicken, classicCheeseburger,
    ]

    // MARK: - Community recipes (COMMUNITY_RECIPES + ADMIN_SUBMISSIONS ingredients/steps)

    static let misoGlazedSalmon = Recipe(
        id: uid(201),
        title: "Miso Glazed Salmon",
        cuisine: "Japanese",
        cookTimeMinutes: 20,
        difficulty: .easy,
        servings: 2,
        imageURL: URL(string: "https://images.unsplash.com/photo-1567529854338-fc097b962123?w=400&h=300&fit=crop&auto=format")!,
        source: .community,
        status: .visible,
        moderationReason: nil,
        moderatedBy: nil,
        uploaderId: naomiCooks.id,
        ingredients: [
            ing("Salmon fillets", "2 (150g each)"),
            ing("White miso paste", "3 tbsp"),
            ing("Mirin", "2 tbsp"),
            ing("Sake", "1 tbsp"),
            ing("Sesame oil", "1 tsp"),
            ing("Sugar", "1 tsp"),
            ing("Spring onions, to garnish", ""),
            ing("Sesame seeds, to garnish", ""),
        ],
        steps: [
            step(1, "Whisk miso, mirin, sake, sesame oil, and sugar into a smooth glaze.", action: .chop),
            step(2, "Pat the salmon fillets dry and coat generously with the glaze. Marinate 20 minutes.", timer: 1200, action: .simmer),
            step(3, "Preheat the oven to 200°C. Line a baking tray with foil.", action: .heat),
            step(4, "Bake the salmon 10–12 minutes until caramelised and just cooked through.", timer: 660, action: .heat),
            step(5, "Garnish with sliced spring onions and sesame seeds. Serve with steamed rice.", action: .toss),
        ],
        ratingAverage: 4.6,
        ratingCount: 89,
        likeCount: 312,
        saveCount: 87,
        createdAt: date(2026, 9, 11)
    )

    static let lambKoftaWithTzatziki = Recipe(
        id: uid(202),
        title: "Lamb Kofta with Tzatziki",
        cuisine: "Mediterranean",
        cookTimeMinutes: 35,
        difficulty: .medium,
        servings: 4,
        imageURL: URL(string: "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&h=300&fit=crop&auto=format")!,
        source: .community,
        status: .visible,
        moderationReason: nil,
        moderatedBy: nil,
        uploaderId: grillMaestro.id,
        ingredients: [
            ing("Ground lamb", "500g"),
            ing("Onion, grated", "1"),
            ing("Garlic, minced", "3 cloves"),
            ing("Cumin", "2 tsp"),
            ing("Coriander", "1 tsp"),
            ing("Cinnamon", "½ tsp"),
            ing("Salt and black pepper, to taste", ""),
            ing("Fresh parsley, chopped, a handful", ""),
            ing("Greek yogurt, for tzatziki", ""),
            ing("Cucumber, for tzatziki", ""),
            ing("Dill, for tzatziki", ""),
            ing("Lemon, for tzatziki", ""),
        ],
        steps: [
            step(1, "Combine lamb, onion, garlic, spices, and parsley. Mix well.", action: .chop),
            step(2, "Shape into 8 oval koftas around metal skewers.", action: .toss),
            step(3, "Grill over high heat 3–4 minutes per side until charred and cooked.", timer: 420, action: .heat),
            step(4, "Meanwhile, make the tzatziki: grate the cucumber, squeeze dry, and mix with yogurt, dill, and lemon.", action: .chop),
            step(5, "Serve the koftas with tzatziki, warm flatbread, and sliced tomatoes.", action: .toss),
        ],
        ratingAverage: 4.3,
        ratingCount: 54,
        likeCount: 204,
        saveCount: 61,
        createdAt: date(2026, 9, 10)
    )

    static let pineappleFriedRice = Recipe(
        id: uid(203),
        title: "Pineapple Fried Rice",
        cuisine: "Thai",
        cookTimeMinutes: 25,
        difficulty: .easy,
        servings: 3,
        imageURL: URL(string: "https://images.unsplash.com/photo-1710091691777-3115088962c4?w=400&h=300&fit=crop&auto=format")!,
        source: .community,
        status: .flagged,
        moderationReason: "Ingredient quantities appear inconsistent (2 cups rice for 8 servings, listed as 2); unverified health claim ('boosts metabolism') in the description.",
        moderatedBy: adminUser.id,
        uploaderId: bangkokKitchen.id,
        ingredients: [
            ing("Cooked jasmine rice, day-old", "2 cups"),
            ing("Pineapple, diced", "1 small"),
            ing("Eggs", "2"),
            ing("Prawns, peeled", "100g"),
            ing("Fish sauce", "3 tbsp"),
            ing("Soy sauce", "1 tbsp"),
            ing("Sugar", "2 tsp"),
            ing("Spring onions, to garnish", ""),
            ing("Cashews, to garnish", ""),
        ],
        steps: [
            step(1, "Heat a wok over high heat until smoking. Add oil.", action: .heat),
            step(2, "Scramble the eggs briefly, then push to the side of the wok.", timer: 60, action: .saute),
            step(3, "Add the prawns and cook 2 minutes. Add the rice and stir-fry 3 minutes.", timer: 300, action: .saute),
            step(4, "Add the pineapple, fish sauce, soy sauce, and sugar. Toss well.", action: .toss),
            step(5, "Serve garnished with cashews and spring onions.", action: .toss),
        ],
        ratingAverage: 4.0,
        ratingCount: 32,
        likeCount: 178,
        saveCount: 44,
        createdAt: date(2026, 9, 10)
    )

    static let brownButterSageGnocchi = Recipe(
        id: uid(204),
        title: "Brown Butter Sage Gnocchi",
        cuisine: "Italian",
        cookTimeMinutes: 40,
        difficulty: .medium,
        servings: 2,
        imageURL: URL(string: "https://images.unsplash.com/photo-1667473775795-41f69ae72c44?w=400&h=300&fit=crop&auto=format")!,
        source: .community,
        status: .visible,
        moderationReason: nil,
        moderatedBy: nil,
        uploaderId: pastaPerfecta.id,
        ingredients: [
            ing("Store-bought potato gnocchi", "500g"),
            ing("Unsalted butter", "80g"),
            ing("Fresh sage leaves", "12"),
            ing("Garlic, halved", "2 cloves"),
            ing("Salt and black pepper, to taste", ""),
            ing("Parmesan, freshly grated, to serve", ""),
            ing("Lemon zest, to finish", ""),
        ],
        steps: [
            step(1, "Cook the gnocchi in boiling salted water until they float, 2–3 minutes. Drain.", timer: 180, action: .boil),
            step(2, "Melt the butter in a wide pan over medium heat. Add the garlic and sage.", action: .heat),
            step(3, "Cook until the butter turns golden and smells nutty — watch closely.", timer: 180, action: .saute),
            step(4, "Remove the garlic. Add the drained gnocchi and toss to coat.", action: .toss),
            step(5, "Plate immediately, top with Parmesan and lemon zest.", action: .toss),
        ],
        ratingAverage: 4.9,
        ratingCount: 71,
        likeCount: 431,
        saveCount: 129,
        createdAt: date(2026, 9, 9)
    )

    static let coconutDalTadka = Recipe(
        id: uid(205),
        title: "Coconut Dal Tadka",
        cuisine: "Indian",
        cookTimeMinutes: 30,
        difficulty: .easy,
        servings: 4,
        imageURL: URL(string: "https://images.unsplash.com/photo-1627906296851-6d9c5e4db592?w=400&h=300&fit=crop&auto=format")!,
        source: .community,
        status: .visible,
        moderationReason: nil,
        moderatedBy: nil,
        uploaderId: spiceRoute.id,
        ingredients: [
            ing("Red lentils, rinsed", "200g"),
            ing("Coconut milk", "400ml"),
            ing("Onion, diced", "1"),
            ing("Garlic", "3 cloves"),
            ing("Ginger, grated", "1 tsp"),
            ing("Turmeric", "1 tsp"),
            ing("Cumin seeds", "1 tsp"),
            ing("Garam masala", "1 tsp"),
            ing("Fresh coriander, to garnish", ""),
        ],
        steps: [
            step(1, "Simmer the lentils with turmeric and 600ml water until soft, about 20 minutes.", timer: 1200, action: .simmer),
            step(2, "Stir in the coconut milk and simmer 5 more minutes.", timer: 300, action: .simmer),
            step(3, "For the tadka: heat oil, then fry the cumin seeds, onion, garlic, and ginger until golden.", timer: 300, action: .saute),
            step(4, "Add the garam masala to the tadka, cook 1 minute, then pour over the dal.", timer: 60, action: .heat),
            step(5, "Serve with rice or naan and fresh coriander.", action: .toss),
        ],
        ratingAverage: 4.2,
        ratingCount: 48,
        likeCount: 267,
        saveCount: 98,
        createdAt: date(2026, 9, 8)
    )

    static let smashBurgersWithSpecialSauce = Recipe(
        id: uid(206),
        title: "Smash Burgers with Special Sauce",
        cuisine: "American",
        cookTimeMinutes: 15,
        difficulty: .easy,
        servings: 2,
        imageURL: URL(string: "https://images.unsplash.com/photo-1636647511729-6703539ba71f?w=400&h=300&fit=crop&auto=format")!,
        source: .community,
        status: .flagged,
        moderationReason: "Photo appears to be stock imagery, not an original cook; recipe duplicates an earlier submission from the same uploader.",
        moderatedBy: adminUser.id,
        uploaderId: weekendGriller.id,
        ingredients: [
            ing("Ground beef 80/20", "300g"),
            ing("American cheese slices", "4"),
            ing("Brioche buns, toasted", "2"),
            ing("Mayonnaise, for special sauce", ""),
            ing("Ketchup, for special sauce", ""),
            ing("Mustard, for special sauce", ""),
            ing("Pickles, for special sauce", ""),
            ing("Onion powder, for special sauce", ""),
        ],
        steps: [
            step(1, "Divide the beef into 2 loose balls. Season generously.", action: .chop),
            step(2, "Heat a cast-iron skillet over high heat until smoking. Place the balls and immediately smash flat.", action: .heat),
            step(3, "Cook 2 minutes, flip, add cheese, and cook 1 more minute.", timer: 180, action: .saute),
            step(4, "Mix the special sauce ingredients. Spread on the toasted buns.", action: .chop),
            step(5, "Assemble with lettuce, tomato, and pickles. Serve immediately.", action: .toss),
        ],
        ratingAverage: 4.7,
        ratingCount: 203,
        likeCount: 589,
        saveCount: 201,
        createdAt: date(2026, 9, 7)
    )

    static let communityRecipes: [Recipe] = [
        misoGlazedSalmon, lambKoftaWithTzatziki, pineappleFriedRice, brownButterSageGnocchi, coconutDalTadka, smashBurgersWithSpecialSauce,
    ]

    static let allRecipes: [Recipe] = libraryRecipes + communityRecipes

    static func recipe(id: UUID) -> Recipe? {
        allRecipes.first { $0.id == id }
    }

    // MARK: - AI variation pool (AI_VARIATIONS — cycled by "Regenerate with AI")

    static let aiVariations: [Recipe] = [
        Recipe(
            id: uid(301), title: "Spiced Coconut Butter Chicken", cuisine: "Indian", cookTimeMinutes: 40,
            difficulty: .medium, servings: 4,
            imageURL: URL(string: "https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=800&q=80")!,
            source: .aiGenerated, status: .visible, moderationReason: nil, moderatedBy: nil, uploaderId: alexUser.id,
            ingredients: [
                ing("Chicken thighs, diced", "600g"), ing("Coconut milk", "400ml"),
                ing("Garam masala", "2 tsp"), ing("Tomato puree", "300g"), ing("Basmati rice, to serve", ""),
            ],
            steps: [
                step(1, "Marinate the diced chicken in spices for 15 minutes.", timer: 900, action: .simmer),
                step(2, "Sauté the chicken until browned on all sides.", timer: 300, action: .saute),
                step(3, "Stir in the tomato puree and coconut milk.", action: .tomato),
                step(4, "Simmer until the sauce thickens and the chicken is cooked through.", timer: 900, action: .simmer),
                step(5, "Toss to coat and serve over basmati rice.", action: .toss),
            ],
            ratingAverage: 4.5, ratingCount: 0, likeCount: 0, saveCount: 0, createdAt: date(2026, 9, 14)
        ),
        Recipe(
            id: uid(302), title: "Smoky Harissa Chicken Tray Bake", cuisine: "North African", cookTimeMinutes: 50,
            difficulty: .easy, servings: 4,
            imageURL: URL(string: "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=800&q=80")!,
            source: .aiGenerated, status: .visible, moderationReason: nil, moderatedBy: nil, uploaderId: alexUser.id,
            ingredients: [
                ing("Chicken thighs", "8"), ing("Harissa paste", "3 tbsp"),
                ing("Red onion, wedged", "1"), ing("Carrots, chopped", "3"), ing("Olive oil", "2 tbsp"),
            ],
            steps: [
                step(1, "Preheat the oven to 200°C.", action: .heat),
                step(2, "Toss the chicken and vegetables with harissa and olive oil.", action: .toss),
                step(3, "Spread everything on a tray and roast until golden and cooked through.", timer: 2400, action: .heat),
                step(4, "Rest 5 minutes before serving.", timer: 300, action: .simmer),
            ],
            ratingAverage: 4.6, ratingCount: 0, likeCount: 0, saveCount: 0, createdAt: date(2026, 9, 14)
        ),
        Recipe(
            id: uid(303), title: "Lemon-Herb Roast Chicken & Roots", cuisine: "French", cookTimeMinutes: 70,
            difficulty: .medium, servings: 4,
            imageURL: URL(string: "https://images.unsplash.com/photo-1518492104633-130d0cc84637?w=800&q=80")!,
            source: .aiGenerated, status: .visible, moderationReason: nil, moderatedBy: nil, uploaderId: alexUser.id,
            ingredients: [
                ing("Whole chicken", "1.5kg"), ing("Lemon", "2"), ing("Fresh thyme, a few sprigs", ""),
                ing("Potatoes, chopped", "4"), ing("Carrots, chopped", "3"), ing("Butter", "3 tbsp"),
            ],
            steps: [
                step(1, "Preheat the oven to 190°C.", action: .heat),
                step(2, "Stuff the chicken cavity with lemon and thyme, then rub with butter.", action: .chop),
                step(3, "Arrange the potatoes and carrots around the chicken in a roasting tray.", action: .toss),
                step(4, "Roast until the chicken is golden and cooked through, about 1 hour.", timer: 3600, action: .heat),
                step(5, "Rest 10 minutes before carving.", timer: 600, action: .simmer),
            ],
            ratingAverage: 4.8, ratingCount: 0, likeCount: 0, saveCount: 0, createdAt: date(2026, 9, 14)
        ),
        Recipe(
            id: uid(304), title: "Tandoori-Style Chicken Skewers", cuisine: "Indian", cookTimeMinutes: 30,
            difficulty: .easy, servings: 3,
            imageURL: URL(string: "https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=800&q=80")!,
            source: .aiGenerated, status: .visible, moderationReason: nil, moderatedBy: nil, uploaderId: alexUser.id,
            ingredients: [
                ing("Chicken breast, cubed", "500g"), ing("Plain yogurt", "150g"),
                ing("Tandoori spice mix", "2 tbsp"), ing("Lemon", "1"),
            ],
            steps: [
                step(1, "Marinate the chicken cubes in yogurt, tandoori spice, and lemon juice for 20 minutes.", timer: 1200, action: .simmer),
                step(2, "Thread the chicken onto skewers.", action: .chop),
                step(3, "Grill over high heat, turning occasionally, until charred and cooked through.", timer: 600, action: .heat),
                step(4, "Serve with extra lemon wedges.", action: .toss),
            ],
            ratingAverage: 4.4, ratingCount: 0, likeCount: 0, saveCount: 0, createdAt: date(2026, 9, 14)
        ),
        Recipe(
            id: uid(305), title: "Miso-Glazed Chicken Thighs", cuisine: "Japanese", cookTimeMinutes: 35,
            difficulty: .easy, servings: 2,
            imageURL: URL(string: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80")!,
            source: .aiGenerated, status: .visible, moderationReason: nil, moderatedBy: nil, uploaderId: alexUser.id,
            ingredients: [
                ing("Chicken thighs", "4"), ing("White miso paste", "3 tbsp"),
                ing("Mirin", "2 tbsp"), ing("Sesame seeds, to garnish", ""),
            ],
            steps: [
                step(1, "Whisk the miso and mirin into a glaze.", action: .chop),
                step(2, "Coat the chicken thighs in the glaze and marinate 15 minutes.", timer: 900, action: .simmer),
                step(3, "Sear the chicken skin-side down until golden, then flip.", timer: 480, action: .saute),
                step(4, "Finish in the oven or covered pan until cooked through.", timer: 600, action: .heat),
                step(5, "Garnish with sesame seeds and serve.", action: .toss),
            ],
            ratingAverage: 4.7, ratingCount: 0, likeCount: 0, saveCount: 0, createdAt: date(2026, 9, 14)
        ),
    ]

    // MARK: - Cook history (HISTORY_ITEMS)

    static let historyEntries: [CookHistoryEntry] = [
        CookHistoryEntry(id: uid(401), recipeId: tonkotsuRamen.id, cookedAt: date(2026, 9, 16, 19, 30), rating: 5, note: "Used chicken broth substitute — worked great!"),
        CookHistoryEntry(id: uid(402), recipeId: spaghettiPomodoro.id, cookedAt: date(2026, 9, 9, 19, 0), rating: 4, note: "Added extra garlic per AI suggestion"),
        CookHistoryEntry(id: uid(403), recipeId: chickenAdobo.id, cookedAt: date(2026, 9, 7, 18, 45), rating: 5, note: nil),
        CookHistoryEntry(id: uid(404), recipeId: streetTacosAlPastor.id, cookedAt: date(2026, 9, 4, 19, 15), rating: 4, note: "Substituted pineapple for mango"),
    ]

    // MARK: - Grocery list (starts empty — populated via "Add to grocery" actions)

    static let groceryItems: [GroceryItem] = []

    // MARK: - Notifications (SEED_NOTIFICATIONS, fixed to point at real recipe ids)

    static let notifications: [AppNotification] = [
        AppNotification(id: uid(501), type: .cooked, fromUserId: naomiCooks.id, recipeId: spaghettiPomodoro.id, recipeName: spaghettiPomodoro.title, createdAt: date(2026, 9, 16, 8, 58), isRead: false, adminReason: nil),
        AppNotification(id: uid(502), type: .liked, fromUserId: chefMarco.id, recipeId: spaghettiPomodoro.id, recipeName: spaghettiPomodoro.title, createdAt: date(2026, 9, 16, 8, 46), isRead: false, adminReason: nil),
        AppNotification(id: uid(503), type: .commented, fromUserId: yukiEats.id, recipeId: tonkotsuRamen.id, recipeName: tonkotsuRamen.title, createdAt: date(2026, 9, 16, 8, 0), isRead: false, adminReason: nil),
        AppNotification(id: uid(504), type: .cooked, fromUserId: amaraKitchen.id, recipeId: spaghettiPomodoro.id, recipeName: spaghettiPomodoro.title, createdAt: date(2026, 9, 16, 6, 0), isRead: true, adminReason: nil),
        AppNotification(id: uid(505), type: .saved, fromUserId: phoebeBakes.id, recipeId: tonkotsuRamen.id, recipeName: tonkotsuRamen.title, createdAt: date(2026, 9, 16, 4, 0), isRead: true, adminReason: nil),
        AppNotification(id: uid(506), type: .liked, fromUserId: naomiCooks.id, recipeId: streetTacosAlPastor.id, recipeName: streetTacosAlPastor.title, createdAt: date(2026, 9, 15, 12, 0), isRead: true, adminReason: nil),
    ]

    // MARK: - Comments (SEED_COMMENTS — seeded on Spaghetti Pomodoro)

    static let comments: [RecipeComment] = [
        RecipeComment(id: uid(601), recipeId: spaghettiPomodoro.id, authorId: naomiCooks.id, text: "Made this last night — incredible depth of flavour from the San Marzanos. I added a small parmesan rind while simmering.", createdAt: date(2026, 9, 16, 6, 30)),
        RecipeComment(id: uid(602), recipeId: spaghettiPomodoro.id, authorId: chefMarco.id, text: "Classic! I swap the shallot for red onion when I want a bit more bite.", createdAt: date(2026, 9, 16, 3, 30)),
        RecipeComment(id: uid(603), recipeId: spaghettiPomodoro.id, authorId: yukiEats.id, text: "Beautiful recipe. Does this work well with gluten-free pasta?", createdAt: date(2026, 9, 15, 9, 0)),
    ]

    // MARK: - Conversations & chat history (CONVERSATIONS + CHAT_HISTORY)

    static let conversations: [Conversation] = [
        Conversation(id: uid(701), participantId: naomiCooks.id, lastMessage: "Thanks! The miso glaze trick really works.", lastMessageAt: date(2026, 9, 16, 10, 11), unreadCount: 2),
        Conversation(id: uid(702), participantId: pastaPerfecta.id, lastMessage: "You should try it with fresh tagliatelle.", lastMessageAt: date(2026, 9, 16, 9, 0), unreadCount: 0),
        Conversation(id: uid(703), participantId: bangkokKitchen.id, lastMessage: "Let me know how the chilli substitution went!", lastMessageAt: date(2026, 9, 15, 18, 0), unreadCount: 1),
        Conversation(id: uid(704), participantId: grillMaestro.id, lastMessage: "I'll send you the marinade recipe 🔥", lastMessageAt: date(2026, 9, 14, 15, 0), unreadCount: 0),
    ]

    static let directMessages: [DirectMessage] = [
        // naomi_cooks
        DirectMessage(id: UUID(), conversationId: uid(701), senderId: naomiCooks.id, text: "Hey! Loved your comment on the ramen recipe 🍜", sentAt: date(2026, 9, 16, 10, 4)),
        DirectMessage(id: UUID(), conversationId: uid(701), senderId: alexUser.id, text: "Thanks! That broth technique is genius. How long do you simmer the bones for?", sentAt: date(2026, 9, 16, 10, 6)),
        DirectMessage(id: UUID(), conversationId: uid(701), senderId: naomiCooks.id, text: "At least 6 hours for a rich result — overnight if you can manage it!", sentAt: date(2026, 9, 16, 10, 8)),
        DirectMessage(id: UUID(), conversationId: uid(701), senderId: alexUser.id, text: "Wow okay, worth it. Does it freeze well?", sentAt: date(2026, 9, 16, 10, 9)),
        DirectMessage(id: UUID(), conversationId: uid(701), senderId: naomiCooks.id, text: "Thanks! The miso glaze trick really works.", sentAt: date(2026, 9, 16, 10, 11)),

        // pasta_perfecta
        DirectMessage(id: UUID(), conversationId: uid(702), senderId: pastaPerfecta.id, text: "Ciao! Saw you saved the gnocchi recipe — let me know if you need tips!", sentAt: date(2026, 9, 15, 9, 0)),
        DirectMessage(id: UUID(), conversationId: uid(702), senderId: alexUser.id, text: "Would love that. I always end up with rubbery gnocchi 😅", sentAt: date(2026, 9, 15, 9, 2)),
        DirectMessage(id: UUID(), conversationId: uid(702), senderId: pastaPerfecta.id, text: "The trick is to work the dough as little as possible. Barely mix.", sentAt: date(2026, 9, 15, 9, 5)),
        DirectMessage(id: UUID(), conversationId: uid(702), senderId: pastaPerfecta.id, text: "You should try it with fresh tagliatelle.", sentAt: date(2026, 9, 16, 9, 0)),

        // bangkok_kitchen
        DirectMessage(id: UUID(), conversationId: uid(703), senderId: alexUser.id, text: "Hey! Can I substitute bird's eye chilli for regular red chilli?", sentAt: date(2026, 9, 15, 17, 50)),
        DirectMessage(id: UUID(), conversationId: uid(703), senderId: bangkokKitchen.id, text: "Yes but use double the amount — bird's eye is much hotter per gram.", sentAt: date(2026, 9, 15, 17, 55)),
        DirectMessage(id: UUID(), conversationId: uid(703), senderId: bangkokKitchen.id, text: "Let me know how the chilli substitution went!", sentAt: date(2026, 9, 15, 18, 0)),

        // grill_maestro
        DirectMessage(id: UUID(), conversationId: uid(704), senderId: grillMaestro.id, text: "Nice BBQ setup you've got! What grill do you use?", sentAt: date(2026, 9, 14, 14, 50)),
        DirectMessage(id: UUID(), conversationId: uid(704), senderId: alexUser.id, text: "Just a basic Weber kettle — works great for most things.", sentAt: date(2026, 9, 14, 14, 55)),
        DirectMessage(id: UUID(), conversationId: uid(704), senderId: grillMaestro.id, text: "I'll send you the marinade recipe 🔥", sentAt: date(2026, 9, 14, 15, 0)),
    ]

    // MARK: - AI cooking chat sample (AI_MESSAGES — canned exchange shown in Cook Mode)

    static let sampleAIChat: [AIChatMessage] = [
        AIChatMessage(id: UUID(), role: .user, text: "What can I substitute for heavy cream in this sauce?", createdAt: date(2026, 9, 16, 19, 0)),
        AIChatMessage(id: UUID(), role: .assistant, text: "Great question! For this sauce, try half-and-half, evaporated milk, or full-fat coconut milk for a richer flavor. If you want to keep it lighter, a splash of pasta water whisked with a bit of butter works beautifully.", createdAt: date(2026, 9, 16, 19, 1)),
    ]

    // MARK: - Pairing pools (PAIRING_POOLS + DEFAULT_PAIRINGS)

    static let pairingPools: [String: [[PairingSuggestion]]] = [
        "Italian": [
            [
                PairingSuggestion(id: UUID(), name: "Garlic Bread", reason: "Crispy and aromatic — perfect for mopping up sauce", emoji: "🥖", linkedRecipeId: nil),
                PairingSuggestion(id: UUID(), name: "Simple Arugula Salad", reason: "Peppery greens cut through the richness of pasta", emoji: "🥗", linkedRecipeId: nil),
            ],
            [
                PairingSuggestion(id: UUID(), name: "Bruschetta", reason: "Fresh tomatoes echo the sauce and add crunch", emoji: "🍅", linkedRecipeId: nil),
                PairingSuggestion(id: UUID(), name: "Sparkling Lemonade", reason: "Bright acidity lifts heavy, cheesy dishes", emoji: "🍋", linkedRecipeId: nil),
            ],
            [
                PairingSuggestion(id: UUID(), name: "Tiramisu", reason: "Classic Italian finish — coffee notes balance tomato acidity", emoji: "☕", linkedRecipeId: nil),
            ],
        ],
        "Indian": [
            [
                PairingSuggestion(id: UUID(), name: "Basmati Rice", reason: "Fluffy grains soak up the curry perfectly", emoji: "🍚", linkedRecipeId: nil),
                PairingSuggestion(id: UUID(), name: "Mango Lassi", reason: "Cool, sweet dairy tames the spice beautifully", emoji: "🥭", linkedRecipeId: nil),
            ],
            [
                PairingSuggestion(id: UUID(), name: "Garlic Naan", reason: "Pillowy bread for scooping rich sauces", emoji: "🫓", linkedRecipeId: nil),
                PairingSuggestion(id: UUID(), name: "Cucumber Raita", reason: "Yogurt and cucumber cool the palate between bites", emoji: "🥒", linkedRecipeId: nil),
            ],
        ],
        "Japanese": [
            [
                PairingSuggestion(id: UUID(), name: "Miso Soup", reason: "Umami-rich broth rounds out the meal", emoji: "🍜", linkedRecipeId: nil),
                PairingSuggestion(id: UUID(), name: "Pickled Ginger", reason: "Cleanses the palate between bites", emoji: "🫚", linkedRecipeId: nil),
            ],
        ],
        "Thai": [
            [
                PairingSuggestion(id: UUID(), name: "Jasmine Rice", reason: "Fragrant and light — balances bold Thai flavours", emoji: "🍚", linkedRecipeId: nil),
                PairingSuggestion(id: UUID(), name: "Thai Iced Tea", reason: "Creamy sweetness offsets heat and spice", emoji: "🧋", linkedRecipeId: nil),
            ],
        ],
        "Mediterranean": [
            [
                PairingSuggestion(id: UUID(), name: "Warm Pita Bread", reason: "Scoopable and neutral to balance bold flavours", emoji: "🫓", linkedRecipeId: nil),
                PairingSuggestion(id: UUID(), name: "Tzatziki", reason: "Cool yogurt-cucumber dip is a natural counterpoint", emoji: "🥒", linkedRecipeId: nil),
            ],
        ],
        "American": [
            [
                PairingSuggestion(id: UUID(), name: "Coleslaw", reason: "Crunchy and tangy — a classic American pairing", emoji: "🥗", linkedRecipeId: nil),
                PairingSuggestion(id: UUID(), name: "Lemonade", reason: "Bright citrus refreshes between hearty bites", emoji: "🍋", linkedRecipeId: nil),
            ],
        ],
    ]

    static let defaultPairings: [[PairingSuggestion]] = [
        [
            PairingSuggestion(id: UUID(), name: "Simple Green Salad", reason: "Light greens refresh the palate between bites", emoji: "🥗", linkedRecipeId: nil),
            PairingSuggestion(id: UUID(), name: "Sparkling Water with Lime", reason: "Clean and bright to balance rich flavours", emoji: "🫧", linkedRecipeId: nil),
        ],
        [
            PairingSuggestion(id: UUID(), name: "Crusty Bread Roll", reason: "Perfect for soaking up any leftover sauce", emoji: "🥐", linkedRecipeId: nil),
        ],
    ]

    static func pairingPool(forCuisine cuisine: String) -> [[PairingSuggestion]] {
        pairingPools[cuisine] ?? defaultPairings
    }

    // MARK: - Swap suggestions (SWAP_SUGGESTIONS — keyed by ingredient name, for Spaghetti Pomodoro)

    static let swapSuggestions: [String: SubstitutionSuggestion] = [
        "Spaghetti": SubstitutionSuggestion(id: UUID(), originalIngredient: "Spaghetti", replacement: "Linguine or fettuccine", note: "Same cook time. Wider noodles will hold slightly more sauce."),
        "San Marzano tomatoes": SubstitutionSuggestion(id: UUID(), originalIngredient: "San Marzano tomatoes", replacement: "Fresh Roma tomatoes, blanched & peeled", note: "Add 5 min extra simmer time to reduce extra liquid."),
        "Garlic": SubstitutionSuggestion(id: UUID(), originalIngredient: "Garlic", replacement: "Garlic powder (1 tsp)", note: "Add with the tomatoes instead of the oil; use ¾ tsp if you prefer milder flavour."),
        "Shallot": SubstitutionSuggestion(id: UUID(), originalIngredient: "Shallot", replacement: "¼ medium white onion, finely diced", note: "Slightly sharper flavour — sauté 1 min longer until fully soft."),
        "Extra-virgin olive oil": SubstitutionSuggestion(id: UUID(), originalIngredient: "Extra-virgin olive oil", replacement: "Light olive oil or avocado oil", note: "Same quantity. Avocado oil has a higher smoke point — great for higher heat."),
        "Sugar": SubstitutionSuggestion(id: UUID(), originalIngredient: "Sugar", replacement: "½ tsp honey or a pinch of baking soda", note: "Baking soda neutralises acidity without adding sweetness. Use sparingly."),
        "Fresh basil leaves, a handful": SubstitutionSuggestion(id: UUID(), originalIngredient: "Fresh basil leaves, a handful", replacement: "1 tsp dried basil", note: "Add with the tomatoes rather than at the end. Use ½ tsp — dried is more concentrated."),
        "Salt and black pepper, to taste": SubstitutionSuggestion(id: UUID(), originalIngredient: "Salt and black pepper, to taste", replacement: "Soy sauce + white pepper", note: "Use ½ tsp soy sauce for salt; white pepper is milder. Adds a subtle umami note."),
        "Parmesan cheese, for serving": SubstitutionSuggestion(id: UUID(), originalIngredient: "Parmesan cheese, for serving", replacement: "Pecorino Romano or nutritional yeast (vegan)", note: "Pecorino is saltier — reduce added salt by a pinch. Nutritional yeast: 2 tbsp per serving."),
    ]

    // MARK: - Login mock accounts

    static let loginAccounts: [User] = [alexUser, adminUser]
}
