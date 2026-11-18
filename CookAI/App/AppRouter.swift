//
//  AppRouter.swift
//  CookAI
//
//  App-wide navigation state: which phase the app is in (splash/auth/main),
//  which tab is active, and each tab's own push-navigation stack. Auth
//  business logic itself lives in AuthController — this router only reacts
//  to phase transitions.
//

import Observation

enum AppPhase {
    case splash
    case auth
    case main
}

enum Tab: String, CaseIterable, Hashable {
    case home
    case discover
    case saved
    case history
    case profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .discover: return "Discover"
        case .saved: return "Saved"
        case .history: return "History"
        case .profile: return "Profile"
        }
    }
}

/// Typed push destinations. Each tab owns its own array of these, so the tab
/// bar can hide itself whenever the active tab's stack is non-empty, mirroring
/// the prototype's single-screen-swap navigation.
enum Route: Hashable {
    case recipeOverview(Recipe)
    case aiGenerate
    case groceryList
    case uploadRecipe
    case cookMode(Recipe)
    case notifications
    case conversations
    case adminDashboard
    case adminUsers
    /// Recipe Management, optionally opened on a status filter and/or a search (e.g. one uploader).
    case adminRecipes(status: RecipeStatus?, search: String?)
    case adminRecipeDetail(Recipe)
    case comingSoon(title: String)
}

@Observable
final class AppRouter {
    var phase: AppPhase = .splash
    var selectedTab: Tab = .home
    var paths: [Tab: [Route]] = Dictionary(uniqueKeysWithValues: Tab.allCases.map { ($0, []) })

    func finishSplash() {
        phase = .auth
    }

    func completeSignIn() {
        selectedTab = .home
        phase = .main
    }

    func signOut() {
        for tab in Tab.allCases {
            paths[tab] = []
        }
        selectedTab = .home
        phase = .auth
    }

    func push(_ route: Route, in tab: Tab? = nil) {
        let target = tab ?? selectedTab
        paths[target, default: []].append(route)
    }

    func pop(in tab: Tab? = nil) {
        let target = tab ?? selectedTab
        guard var path = paths[target], !path.isEmpty else { return }
        path.removeLast()
        paths[target] = path
    }
}
