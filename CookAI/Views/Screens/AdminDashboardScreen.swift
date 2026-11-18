//
//  AdminDashboardScreen.swift
//  CookAI
//
//  Admin Dashboard (screen 1 of the admin flow): four live stat cards, the
//  latest community submissions, the recipes this admin has handled, and a
//  shortcut to Recipe Management. Every number comes from the database.
//

import SwiftUI

struct AdminDashboardScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var controller = AdminDashboardController()

    private let gridColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            AdminHeader(title: "Admin Dashboard", subtitle: controller.todayText) { dismiss() }
            content
        }
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        // Also runs when coming back from the other admin screens, so numbers stay current.
        .onAppear { Task { await controller.load() } }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if controller.stats == nil && controller.isLoading {
            ProgressView()
                .tint(Color.terracotta)
                .padding(.top, 64)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else if controller.stats == nil, let message = controller.errorMessage {
            errorState(message)
        } else if let stats = controller.stats {
            ScrollView {
                VStack(spacing: 20) {
                    statGrid(stats)
                    recentSection
                    if !controller.handledByMe.isEmpty {
                        handledSection
                    }
                    manageButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .refreshable { await controller.load() }
        } else {
            Spacer()
        }
    }

    // MARK: - Stat cards

    private struct StatCard: Identifiable {
        let id: String
        let icon: String
        let value: Int
        let label: String
        let note: String
        let route: Route
        var urgent = false
    }

    private func cards(for stats: AdminStats) -> [StatCard] {
        [
            StatCard(id: "users", icon: "👥", value: stats.totalUsers, label: "Total Users",
                     note: "+\(stats.usersToday) today", route: .adminUsers),
            StatCard(id: "recipes", icon: "🍽", value: stats.totalRecipes, label: "Total Recipes",
                     note: "+\(stats.recipesToday) today", route: .adminRecipes(status: nil, search: nil)),
            StatCard(id: "week", icon: "📅", value: stats.recipesThisWeek, label: "This Week",
                     note: "recipes submitted", route: .adminRecipes(status: nil, search: nil)),
            StatCard(id: "flagged", icon: "🚩", value: stats.flagged, label: "Flagged",
                     note: stats.flagged > 0 ? "needs review" : "all clear",
                     route: .adminRecipes(status: .flagged, search: nil), urgent: stats.flagged > 0),
        ]
    }

    private func statGrid(_ stats: AdminStats) -> some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(cards(for: stats)) { card in
                Button {
                    router.push(card.route)
                } label: {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Text(card.icon)
                            .font(.system(size: 24))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.charcoalPale)
                    }
                    .padding(.bottom, 8)
                    Text("\(card.value)")
                        .font(.outfit(size: 24, weight: .bold))
                        .foregroundStyle(Color.charcoal)
                        .padding(.bottom, 4)
                    Text(card.label)
                        .font(.outfit(size: 12, weight: .semibold))
                        .foregroundStyle(Color.charcoalMid)
                    Text(card.note)
                        .font(.outfit(size: 11))
                        .foregroundStyle(card.urgent ? Color.terracotta : Color.sage)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.terracotta.opacity(card.urgent ? 0.25 : 0), lineWidth: 1)
                )
                .softShadow()
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Lists

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Submissions")
                    .font(.lora(size: 16, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                Spacer()
                Button {
                    router.push(.adminRecipes(status: nil, search: nil))
                } label: {
                    Text("See all →")
                        .font(.outfit(size: 14, weight: .semibold))
                        .foregroundStyle(Color.terracotta)
                }
                .buttonStyle(.plain)
            }

            if controller.recent.isEmpty {
                emptyCard("No community recipes yet. Recipes your users share will show up here.")
            } else {
                recipeList(controller.recent)
            }
        }
    }

    private var handledSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Handled by you")
                .font(.lora(size: 16, weight: .semibold))
                .foregroundStyle(Color.charcoal)
            recipeList(controller.handledByMe)
        }
    }

    private func recipeList(_ recipes: [Recipe]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(recipes.enumerated()), id: \.element.id) { index, recipe in
                if index > 0 {
                    Divider().overlay(Color.creamBorder)
                }
                Button {
                    router.push(.adminRecipeDetail(recipe))
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(recipe.title)
                                .font(.outfit(size: 14, weight: .semibold))
                                .foregroundStyle(Color.charcoal)
                                .lineLimit(1)
                            Text(subtitle(for: recipe))
                                .font(.outfit(size: 11))
                                .foregroundStyle(Color.charcoalLight)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        AdminStatusPill(status: recipe.status)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.charcoalPale)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .softShadow()
    }

    private func subtitle(for recipe: Recipe) -> String {
        let who = controller.uploader(for: recipe).map { "@\($0.username)" } ?? "Unknown cook"
        let date = recipe.createdAt.formatted(.dateTime.month(.abbreviated).day().year())
        return "\(who) · \(date)"
    }

    private func emptyCard(_ text: String) -> some View {
        Text(text)
            .font(.outfit(size: 13))
            .foregroundStyle(Color.charcoalLight)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .softShadow()
    }

    // MARK: - Manage button

    private var manageButton: some View {
        Button {
            router.push(.adminRecipes(status: nil, search: nil))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.terracotta)
                    .frame(width: 40, height: 40)
                    .background(Color.terracotta.opacity(0.1), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Manage All Recipes")
                        .font(.outfit(size: 14, weight: .semibold))
                        .foregroundStyle(Color.charcoal)
                    Text("Search, filter, review & remove")
                        .font(.outfit(size: 11))
                        .foregroundStyle(Color.charcoalLight)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.charcoalPale)
            }
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.terracotta.opacity(0.15), lineWidth: 1))
            .softShadow()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Error

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoalLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await controller.load() }
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
        .padding(.top, 64)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    NavigationStack {
        AdminDashboardScreen()
    }
    .environment(AppRouter())
}
