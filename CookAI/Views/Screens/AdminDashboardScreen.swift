//
//  AdminDashboardScreen.swift
//  CookAI
//
//  Admin-only moderation. Four tabs: Flagged (needs a decision), Live,
//  Removed, and My actions (everything this admin has handled). Admins can
//  Approve, Flag or Remove community recipes; Flag and Remove ask for a
//  reason that is sent to the cook as a notification. Admins can also upload
//  recipes like anyone else but can't moderate their own.
//

import SwiftUI

struct AdminDashboardScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var controller = AdminDashboardController()
    @State private var pendingAction: PendingAction?

    private struct PendingAction: Identifiable {
        let recipe: Recipe
        let status: RecipeStatus
        var id: String { "\(recipe.id.uuidString)-\(status.rawValue)" }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            filterChips
            messageBanner
            content
        }
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await controller.load() }
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

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            CustomBackButton { dismiss() }
            VStack(alignment: .leading, spacing: 2) {
                Text("Admin Dashboard")
                    .font(.lora(size: 22, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                Text("Review what the community shares")
                    .font(.outfit(size: 13))
                    .foregroundStyle(Color.charcoalLight)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AdminDashboardController.Filter.allCases) { filter in
                    CategoryChip(
                        title: "\(filter.rawValue) \(controller.recipes(for: filter).count)",
                        isActive: controller.selectedFilter == filter
                    ) {
                        controller.selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Messages

    @ViewBuilder
    private var messageBanner: some View {
        if let error = controller.errorMessage, !controller.visibleRecipes.isEmpty, pendingAction == nil {
            banner(error, color: Color.terracottaDark)
        } else if let notice = controller.noticeMessage {
            banner(notice, color: Color.sage)
        }
    }

    private func banner(_ text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(text)
                .font(.outfit(size: 13))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                controller.dismissMessages()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: - List

    private var content: some View {
        Group {
            if controller.isLoading && controller.visibleRecipes.isEmpty {
                ProgressView()
                    .tint(Color.terracotta)
                    .padding(.top, 64)
            } else if let message = controller.errorMessage, controller.visibleRecipes.isEmpty {
                errorState(message)
            } else if controller.visibleRecipes.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(controller.visibleRecipes) { recipe in
                    ModerationRowCard(
                        recipe: recipe,
                        uploader: controller.uploader(for: recipe),
                        isOwnRecipe: controller.isOwnRecipe(recipe),
                        isWorking: controller.workingRecipeId == recipe.id,
                        onOpen: { router.push(.recipeOverview(recipe)) },
                        onApprove: { Task { await controller.moderate(recipe, to: .visible, reason: nil) } },
                        onFlag: {
                            controller.dismissMessages()
                            pendingAction = PendingAction(recipe: recipe, status: .flagged)
                        },
                        onRemove: {
                            controller.dismissMessages()
                            pendingAction = PendingAction(recipe: recipe, status: .removed)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .refreshable { await controller.load() }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text(emptyEmoji).font(.system(size: 36))
            Text(emptyText)
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoalLight)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
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
    }

    private var emptyEmoji: String {
        switch controller.selectedFilter {
        case .flagged: return "✅"
        case .live: return "🍽️"
        case .removed: return "🗑️"
        case .mine: return "🛡️"
        }
    }

    private var emptyText: String {
        switch controller.selectedFilter {
        case .flagged: return "Nothing is flagged. All clear!"
        case .live: return "No live community recipes yet."
        case .removed: return "No removed recipes."
        case .mine: return "You haven't approved, flagged or removed anything yet."
        }
    }
}

#Preview {
    NavigationStack {
        AdminDashboardScreen()
    }
    .environment(AppRouter())
}
