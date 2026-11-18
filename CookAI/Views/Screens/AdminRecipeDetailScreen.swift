//
//  AdminRecipeDetailScreen.swift
//  CookAI
//
//  Recipe Detail, admin view (screen 3 of the admin flow): photo, the recipe,
//  who submitted it (with their email, visible to admins only), the reason it
//  was flagged or removed, and a fixed Approve / Flag / Remove bar. Flag and
//  Remove ask for a reason that the uploader receives as a notification.
//

import SwiftUI

struct AdminRecipeDetailScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var controller: AdminRecipeDetailController
    @State private var showSteps = false
    @State private var pendingAction: PendingAction?

    private struct PendingAction: Identifiable {
        let status: RecipeStatus
        var id: String { status.rawValue }
    }

    init(recipe: Recipe) {
        _controller = State(initialValue: AdminRecipeDetailController(recipe: recipe))
    }

    private var recipe: Recipe { controller.recipe }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                VStack(spacing: 20) {
                    infoCard
                        .padding(.top, -40)
                    submissionInfo
                    reasonBox
                    ingredientsSection
                    instructionsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
        .task { await controller.load() }
        .sheet(item: $pendingAction) { action in
            ModerationReasonSheet(
                recipeTitle: recipe.title,
                status: action.status,
                isWorking: controller.isWorking,
                errorMessage: controller.errorMessage,
                onConfirm: { reason in
                    Task {
                        if await controller.moderate(to: action.status, reason: reason) {
                            pendingAction = nil
                        }
                    }
                },
                onCancel: { pendingAction = nil }
            )
        }
    }

    // MARK: - Hero

    private var hero: some View {
        Color(hex: "#E8DDD5")
            .frame(height: 300)
            .overlay {
                AsyncImage(url: recipe.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "fork.knife")
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(Color.charcoalLight)
                    default:
                        Color.cream
                    }
                }
            }
            .clipped()
            .overlay {
                LinearGradient(colors: [.clear, .black.opacity(0.4)], startPoint: .center, endPoint: .bottom)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .top) {
                HStack {
                    CustomBackButton { dismiss() }
                    Spacer()
                    AdminBadge(text: "🛡 ADMIN VIEW")
                }
                .padding(.horizontal, 16)
                .padding(.top, 56)
            }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Text(recipe.title)
                    .font(.lora(size: 18, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                AdminStatusPill(status: recipe.status)
            }
            HStack(spacing: 20) {
                fact("🌍", recipe.cuisine)
                fact("👥", "\(recipe.servings) servings")
                fact("📊", recipe.difficulty.rawValue)
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.charcoal.opacity(0.12), radius: 16, x: 0, y: 8)
    }

    private func fact(_ icon: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(icon).font(.system(size: 14))
            Text(label)
                .font(.outfit(size: 11, weight: .medium))
                .foregroundStyle(Color.charcoalMid)
        }
    }

    // MARK: - Submission info + reason

    private var submissionInfo: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("🛡 SUBMISSION INFO")
                .font(.outfit(size: 10, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(Color.terracotta)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            Divider().overlay(Color.creamBorder)

            HStack(spacing: 12) {
                Text(initial)
                    .font(.lora(size: 14, weight: .bold))
                    .foregroundStyle(avatarColor)
                    .frame(width: 36, height: 36)
                    .background(avatarColor.opacity(0.15), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(controller.uploader.map { "@\($0.username)" } ?? "Unknown cook")
                        .font(.outfit(size: 14, weight: .semibold))
                        .foregroundStyle(Color.charcoal)
                    Text(controller.uploaderEmail ?? "Email unavailable")
                        .font(.outfit(size: 12))
                        .foregroundStyle(Color.charcoalLight)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("SUBMITTED")
                        .font(.outfit(size: 10, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color.charcoalLight)
                    Text(controller.submittedText)
                        .font(.outfit(size: 12, weight: .medium))
                        .foregroundStyle(Color.charcoalMid)
                }
            }
            .padding(16)
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))
    }

    private var initial: String {
        controller.uploader?.username.first.map { String($0).uppercased() } ?? "?"
    }

    private var avatarColor: Color {
        controller.uploader.map { Color(hex: $0.avatarColorHex) } ?? Color.terracotta
    }

    @ViewBuilder
    private var reasonBox: some View {
        if recipe.status != .visible, let reason = recipe.moderationReason, !reason.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12, weight: .semibold))
                    Text(recipe.status == .flagged ? "FLAG REASON" : "REMOVAL REASON")
                        .font(.outfit(size: 11, weight: .bold))
                        .tracking(0.6)
                }
                .foregroundStyle(Color.terracotta)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                Divider().overlay(Color.terracotta.opacity(0.15))

                HStack(alignment: .top, spacing: 10) {
                    Text("1.")
                        .font(.outfit(size: 11, weight: .bold))
                        .foregroundStyle(Color.terracotta)
                    Text(reason)
                        .font(.outfit(size: 13))
                        .foregroundStyle(Color.charcoalMid)
                        .lineSpacing(3)
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.terracotta.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.terracotta.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: - Ingredients + instructions

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.lora(size: 18, weight: .semibold))
                .foregroundStyle(Color.charcoal)
            VStack(spacing: 10) {
                ForEach(recipe.ingredients) { ingredient in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Circle()
                            .fill(Color.sage)
                            .frame(width: 6, height: 6)
                            .offset(y: -2)
                        Text(ingredient.name)
                            .font(.outfit(size: 14))
                            .foregroundStyle(Color.charcoal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(ingredient.quantity)
                            .font(.outfit(size: 13))
                            .foregroundStyle(Color.charcoalLight)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showSteps.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Instructions")
                            .font(.lora(size: 16, weight: .semibold))
                            .foregroundStyle(Color.charcoal)
                        Text("\(recipe.steps.count) steps")
                            .font(.outfit(size: 12))
                            .foregroundStyle(Color.charcoalLight)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.charcoalLight)
                        .rotationEffect(.degrees(showSteps ? 180 : 0))
                }
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().overlay(Color.creamBorder)

            if showSteps {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(recipe.steps.sorted { $0.order < $1.order }) { step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(step.order)")
                                .font(.outfit(size: 11, weight: .bold))
                                .foregroundStyle(Color.terracotta)
                                .frame(width: 24, height: 24)
                                .background(Color.terracotta.opacity(0.15), in: Circle())
                            Text(step.text)
                                .font(.outfit(size: 14))
                                .foregroundStyle(Color.charcoalMid)
                                .lineSpacing(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.top, 16)
            }
        }
    }

    // MARK: - Admin action bar

    private var actionBar: some View {
        VStack(spacing: 12) {
            if let error = controller.errorMessage, pendingAction == nil {
                AdminMessageBanner(text: error, color: Color(hex: "#9C2B2B")) { controller.dismissMessages() }
            } else if let notice = controller.noticeMessage {
                AdminMessageBanner(text: notice, color: Color.sage) { controller.dismissMessages() }
            }

            Text("ADMIN ACTIONS")
                .font(.outfit(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.charcoalLight)

            if controller.isOwnRecipe {
                Text("This is your own recipe, so another admin has to review it.")
                    .font(.outfit(size: 12))
                    .foregroundStyle(Color.charcoalLight)
                    .multilineTextAlignment(.center)
            } else {
                HStack(spacing: 8) {
                    actionButton("Approve", symbol: "checkmark", tint: Color.sage, enabled: recipe.status != .visible) {
                        controller.dismissMessages()
                        Task { await controller.moderate(to: .visible, reason: nil) }
                    }
                    actionButton("Flag", symbol: "flag", tint: Color(hex: "#B8860B"), enabled: recipe.status != .flagged) {
                        controller.dismissMessages()
                        pendingAction = PendingAction(status: .flagged)
                    }
                    actionButton("Remove", symbol: "trash", tint: Color(hex: "#9C2B2B"), enabled: recipe.status != .removed) {
                        controller.dismissMessages()
                        pendingAction = PendingAction(status: .removed)
                    }
                }
                .disabled(controller.isWorking)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.96).ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Divider().overlay(Color.creamBorder) }
    }

    private func actionButton(_ title: String, symbol: String, tint: Color, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.outfit(size: 12, weight: .semibold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(tint.opacity(0.3), lineWidth: 1))
            .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
