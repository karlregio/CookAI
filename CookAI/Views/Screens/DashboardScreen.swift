//
//  DashboardScreen.swift
//  CookAI
//
//  Home tab root. Ports DashboardScreen from App.tsx (~lines 901–1061):
//  greeting header with notification/messages icons, search, cuisine chips,
//  and a 2-column recipe grid with loading/error/empty states and
//  pull-to-refresh.
//

import SwiftUI

struct DashboardScreen: View {
    private let categories = ["All", "Filipino", "Italian", "Japanese", "Mexican", "Indian", "American", "AI Generate"]
    private let gridColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    @Environment(AppRouter.self) private var router
    @Environment(AuthController.self) private var auth
    @State private var controller = DashboardController()

    var body: some View {
        VStack(spacing: 0) {
            header
            searchAndChips
            content
        }
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await controller.loadIfNeeded() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(greeting)
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoalLight)

                Spacer()

                HStack(spacing: 8) {
                    // Notifications is a finals-only feature (PROJECT_RULES.md #6);
                    // the entry point stays visible but opens ComingSoonScreen.
                    headerIconButton(systemName: "bell", badge: controller.unreadNotificationCount) {
                        router.push(.notifications)
                    }
                    // Messages is also finals-only — no unread count exists yet, so
                    // no badge is shown rather than fabricating one.
                    headerIconButton(systemName: "message", badge: 0) {
                        router.push(.conversations)
                    }
                }
            }

            Text("What are we cooking\ntoday?")
                .font(.lora(size: 24, weight: .semibold))
                .foregroundStyle(Color.charcoal)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    /// Always derived from AuthController — never a hardcoded name. Guests
    /// (no signed-in user) get a neutral, time-of-day-only greeting.
    private var greeting: String {
        let timeOfDay = timeOfDayGreeting()
        guard let user = auth.currentUser, !user.displayName.isEmpty else {
            return "\(timeOfDay) 👋"
        }
        let firstName = user.displayName.split(separator: " ").first.map(String.init) ?? user.displayName
        return "\(timeOfDay), \(firstName) 👋"
    }

    private func timeOfDayGreeting() -> String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func headerIconButton(systemName: String, badge: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.charcoalMid)
                    .frame(width: 36, height: 36)
                    .background(Color.white, in: Circle())
                    .overlay(Circle().stroke(Color.creamBorder, lineWidth: 1))
                    .softShadow()

                if badge > 0 {
                    Text(badge > 9 ? "9+" : "\(badge)")
                        .font(.outfit(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Color.terracotta, in: Circle())
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search + chips

    private var searchAndChips: some View {
        VStack(alignment: .leading, spacing: 16) {
            SearchBar(text: $controller.searchText)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        CategoryChip(
                            title: category,
                            isAIGenerate: category == "AI Generate",
                            isActive: controller.selectedCategory == category
                        ) {
                            if category == "AI Generate" {
                                router.push(.aiGenerate)
                            } else {
                                controller.selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Content

    private var content: some View {
        Group {
            if controller.isLoading && controller.recipes.isEmpty {
                loadingGrid
            } else if let errorMessage = controller.errorMessage, controller.recipes.isEmpty {
                errorState(errorMessage)
            } else if controller.filteredRecipes.isEmpty {
                emptyState
            } else {
                recipeGrid
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var recipeGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(controller.filteredRecipes) { recipe in
                    RecipeCard(recipe: recipe, uploader: controller.uploader(for: recipe)) {
                        router.push(.recipeOverview(recipe))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .refreshable {
            await controller.load()
        }
    }

    private var loadingGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    RecipeCardPlaceholder()
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🍽").font(.system(size: 36))
            Text("No recipes found")
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoalLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 64)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoalLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await controller.retry() }
            } label: {
                Text("Retry")
                    .font(.outfit(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.terracotta, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 64)
    }
}

private struct RecipeCardPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.charcoal.opacity(0.06))
                .aspectRatio(1.5, contentMode: .fit)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.charcoal.opacity(0.08))
                    .frame(height: 12)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.charcoal.opacity(0.06))
                    .frame(width: 72, height: 10)
            }
            .padding(12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .redacted(reason: .placeholder)
    }
}

#Preview {
    NavigationStack {
        DashboardScreen()
    }
    .environment(AppRouter())
    .environment(AuthController())
}
