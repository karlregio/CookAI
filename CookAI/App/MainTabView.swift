//
//  MainTabView.swift
//  CookAI
//
//  The signed-in app shell: five tabs, each with its own NavigationStack and
//  Route-typed push stack, plus a custom bottom tab bar (not the system
//  TabView chrome) that hides itself whenever the active tab has pushed a
//  detail screen — mirroring the prototype's single-screen-swap navigation.
//
//  Uses TabView (with its native bar fully hidden) rather than manually
//  swapping content, so each tab's NavigationStack — and any @State inside
//  its root screen, like DashboardController's search/category/loaded data —
//  survives switching tabs instead of being torn down and rebuilt.
//

import SwiftUI

struct MainTabView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        TabView(selection: selectedTabBinding) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabStack(tab)
                    .tag(tab)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isTabBarVisible {
                CustomTabBar(active: router.selectedTab) { router.selectedTab = $0 }
            }
        }
    }

    private var selectedTabBinding: Binding<Tab> {
        Binding(get: { router.selectedTab }, set: { router.selectedTab = $0 })
    }

    private var isTabBarVisible: Bool {
        (router.paths[router.selectedTab] ?? []).isEmpty
    }

    @ViewBuilder
    private func tabStack(_ tab: Tab) -> some View {
        NavigationStack(path: pathBinding(for: tab)) {
            rootView(for: tab)
                .navigationDestination(for: Route.self) { route in
                    RouteDestinationView(route: route)
                }
        }
    }

    @ViewBuilder
    private func rootView(for tab: Tab) -> some View {
        switch tab {
        case .home:
            DashboardScreen()
        case .saved, .grocery, .history, .profile:
            TabPlaceholderScreen(tab: tab)
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
            RecipeOverviewScreen(recipe: recipe)
        case .aiGenerate:
            ComingSoonScreen(title: "AI Generate")
        case .cookMode(let recipe):
            CookModeScreen(recipe: recipe)
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
        .environment(AuthController())
        .environment(GroceryController())
}
