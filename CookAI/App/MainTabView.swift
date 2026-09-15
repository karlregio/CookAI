//
//  MainTabView.swift
//  CookAI
//
//  The signed-in app shell: five tabs, each with its own NavigationStack and
//  Route-typed push stack, plus a custom bottom tab bar (not the system
//  TabView chrome) that hides itself whenever the active tab has pushed a
//  detail screen — mirroring the prototype's single-screen-swap navigation.
//

import SwiftUI

struct MainTabView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        Group {
            switch router.selectedTab {
            case .home:
                tabStack(.home) { TabPlaceholderScreen(tab: .home) }
            case .saved:
                tabStack(.saved) { TabPlaceholderScreen(tab: .saved) }
            case .grocery:
                tabStack(.grocery) { TabPlaceholderScreen(tab: .grocery) }
            case .history:
                tabStack(.history) { TabPlaceholderScreen(tab: .history) }
            case .profile:
                tabStack(.profile) { TabPlaceholderScreen(tab: .profile) }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isTabBarVisible {
                CustomTabBar(active: router.selectedTab) { router.selectedTab = $0 }
            }
        }
    }

    private var isTabBarVisible: Bool {
        (router.paths[router.selectedTab] ?? []).isEmpty
    }

    @ViewBuilder
    private func tabStack<Root: View>(_ tab: Tab, @ViewBuilder root: () -> Root) -> some View {
        NavigationStack(path: pathBinding(for: tab)) {
            root()
                .navigationDestination(for: Route.self) { route in
                    RouteDestinationView(route: route)
                }
        }
    }

    private func pathBinding(for tab: Tab) -> Binding<[Route]> {
        Binding(
            get: { router.paths[tab] ?? [] },
            set: { router.paths[tab] = $0 }
        )
    }
}

private struct RouteDestinationView: View {
    let route: Route

    var body: some View {
        switch route {
        case .recipeOverview(let recipe):
            ComingSoonScreen(title: recipe.title)
        case .aiGenerate:
            ComingSoonScreen(title: "AI Generate")
        case .cookMode(let recipe):
            ComingSoonScreen(title: "Cook Mode: \(recipe.title)")
        case .notifications:
            ComingSoonScreen(title: "Notifications")
        case .conversations:
            ComingSoonScreen(title: "Messages")
        case .comingSoon(let title):
            ComingSoonScreen(title: title)
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppRouter())
}
