//
//  AdminRecipesScreen.swift
//  CookAI
//
//  Recipe Management (screen 2 of the admin flow): search by title or
//  uploader, filter by status with live counts, and a compact table of every
//  community recipe. The row icons flag or remove a recipe (both ask for a
//  reason first); tapping a row opens the admin detail view.
//

import SwiftUI

struct AdminRecipesScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var controller: AdminRecipesController
    @State private var pendingAction: PendingAction?

    private struct PendingAction: Identifiable {
        let recipe: Recipe
        let status: RecipeStatus
        var id: String { "\(recipe.id.uuidString)-\(status.rawValue)" }
    }

    /// Opens on an optional status filter and/or search text (e.g. one uploader's recipes).
    init(status: RecipeStatus? = nil, search: String? = nil) {
        _controller = State(initialValue: AdminRecipesController(status: status, search: search))
    }

    var body: some View {
        VStack(spacing: 0) {
            AdminHeader(title: "Recipe Management") { dismiss() }
            searchAndFilters
            messageBanner
            Divider().overlay(Color.creamBorder)
            content
        }
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        // Also runs when coming back from the detail screen, so changes show up.
        .onAppear { Task { await controller.load() } }
        .sheet(item: $pendingAction) { action in
            ModerationReasonSheet(
                recipeTitle: action.recipe.title,
                status: action.status,
                isWorking: controller.workingRecipeId != nil,
                errorMessage: controller.errorMessage,
                onConfirm: { reason in
                    Task {
                        if await controller.moderate(action.recipe, to: action.status, reason: reason) {
                            pendingAction = nil
                        }
                    }
                },
                onCancel: { pendingAction = nil }
            )
        }
    }

    // MARK: - Search + filters

    private var searchAndFilters: some View {
        VStack(alignment: .leading, spacing: 12) {
            SearchBar(text: $controller.searchText, placeholder: "Search by title or uploader...")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AdminRecipesController.StatusFilter.allCases) { filter in
                        CategoryChip(
                            title: filter == .all ? "All" : "\(filter.rawValue) \(controller.count(for: filter))",
                            isActive: controller.selectedFilter == filter
                        ) {
                            controller.selectedFilter = filter
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var messageBanner: some View {
        if pendingAction == nil, let error = controller.errorMessage, !controller.shownRecipes.isEmpty {
            AdminMessageBanner(text: error, color: Color(hex: "#9C2B2B")) { controller.dismissMessages() }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        } else if let notice = controller.noticeMessage {
            AdminMessageBanner(text: notice, color: Color.sage) { controller.dismissMessages() }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
    }

    // MARK: - Table

    @ViewBuilder
    private var content: some View {
        if !controller.hasLoaded && controller.recipes.isEmpty {
            ProgressView()
                .tint(Color.terracotta)
                .padding(.top, 64)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else if let message = controller.errorMessage, controller.recipes.isEmpty {
            errorState(message)
        } else if controller.shownRecipes.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    columnHeader
                    ForEach(controller.shownRecipes) { recipe in
                        row(recipe)
                    }
                }
                .padding(.bottom, 24)
            }
            .refreshable { await controller.load() }
        }
    }

    private var columnHeader: some View {
        HStack(spacing: 12) {
            Text("RECIPE / UPLOADER")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("STATUS")
                .frame(width: 72)
            Text("ACTIONS")
                .frame(width: 56)
        }
        .font(.outfit(size: 10, weight: .semibold))
        .tracking(0.8)
        .foregroundStyle(Color.charcoalLight)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func row(_ recipe: Recipe) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    router.push(.adminRecipeDetail(recipe))
                } label: {
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
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                AdminStatusPill(status: recipe.status)
                    .frame(width: 72)

                actions(for: recipe)
                    .frame(width: 56)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(recipe.status == .flagged ? Color.terracotta.opacity(0.04) : Color.clear)
            .opacity(recipe.status == .removed ? 0.6 : 1)

            Divider().overlay(Color.creamBorder)
        }
    }

    @ViewBuilder
    private func actions(for recipe: Recipe) -> some View {
        if controller.isOwnRecipe(recipe) {
            Text("Yours")
                .font(.outfit(size: 10, weight: .semibold))
                .foregroundStyle(Color.charcoalLight)
        } else {
            HStack(spacing: 2) {
                switch recipe.status {
                case .visible:
                    iconButton("flag", tint: Color.charcoalPale) {
                        controller.dismissMessages()
                        pendingAction = PendingAction(recipe: recipe, status: .flagged)
                    }
                    iconButton("trash", tint: Color.charcoalPale) {
                        controller.dismissMessages()
                        pendingAction = PendingAction(recipe: recipe, status: .removed)
                    }
                case .flagged:
                    iconButton("flag.fill", tint: Color.terracotta) {
                        // Un-flag: back to visible, no reason needed.
                        Task { await controller.moderate(recipe, to: .visible, reason: nil) }
                    }
                    iconButton("trash", tint: Color.charcoalPale) {
                        controller.dismissMessages()
                        pendingAction = PendingAction(recipe: recipe, status: .removed)
                    }
                case .removed:
                    iconButton("arrow.uturn.backward", tint: Color.sage) {
                        Task { await controller.moderate(recipe, to: .visible, reason: nil) }
                    }
                }
            }
            .disabled(controller.workingRecipeId != nil)
        }
    }

    private func iconButton(_ symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 26, height: 30)
        }
        .buttonStyle(.plain)
    }

    private func subtitle(for recipe: Recipe) -> String {
        let who = controller.uploader(for: recipe).map { "@\($0.username)" } ?? "Unknown cook"
        let date = recipe.createdAt.formatted(.dateTime.month(.abbreviated).day().year())
        return "\(who) · \(date)"
    }

    // MARK: - Empty / error

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🔍").font(.system(size: 36))
            Text(controller.recipes.isEmpty ? "No community recipes yet" : "No recipes match your filter")
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoalLight)
        }
        .padding(.top, 64)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

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
        AdminRecipesScreen()
    }
    .environment(AppRouter())
}
