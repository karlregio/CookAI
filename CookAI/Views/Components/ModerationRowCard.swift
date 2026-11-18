//
//  ModerationRowCard.swift
//  CookAI
//
//  One recipe in the admin dashboard: photo, title, who shared it, its status,
//  the moderator's reason (if any) and the actions that make sense for that
//  status. Tapping the photo or title opens the full recipe to review it.
//

import SwiftUI

struct ModerationRowCard: View {
    let recipe: Recipe
    let uploader: User?
    let isOwnRecipe: Bool
    let isWorking: Bool
    let onOpen: () -> Void
    let onApprove: () -> Void
    let onFlag: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onOpen) {
                HStack(spacing: 12) {
                    thumbnail
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.title)
                            .font(.lora(size: 15, weight: .semibold))
                            .foregroundStyle(Color.charcoal)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Text(subtitle)
                            .font(.outfit(size: 12))
                            .foregroundStyle(Color.charcoalLight)
                            .lineLimit(1)
                        statusPill
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.charcoalPale)
                }
            }
            .buttonStyle(.plain)

            if let reason = recipe.moderationReason, !reason.isEmpty {
                Text("Reason: \(reason)")
                    .font(.outfit(size: 12))
                    .foregroundStyle(Color.charcoalMid)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cream, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            actions
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .softShadow()
        .opacity(isWorking ? 0.6 : 1)
    }

    // MARK: - Pieces

    private var thumbnail: some View {
        AsyncImage(url: recipe.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                Image(systemName: "fork.knife")
                    .foregroundStyle(Color.charcoalLight)
            default:
                Color.cream
            }
        }
        .frame(width: 64, height: 64)
        .background(Color(hex: "#E8DDD5"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var subtitle: String {
        let who = uploader.map { "@\($0.username)" } ?? "Unknown cook"
        return "\(who) · \(recipe.cuisine)"
    }

    private var statusPill: some View {
        Text(statusTitle)
            .font(.outfit(size: 10, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.14), in: Capsule())
    }

    private var statusTitle: String {
        switch recipe.status {
        case .visible: return "LIVE"
        case .flagged: return "FLAGGED"
        case .removed: return "REMOVED"
        }
    }

    private var statusColor: Color {
        switch recipe.status {
        case .visible: return Color.sage
        case .flagged: return Color.terracotta
        case .removed: return Color.terracottaDark
        }
    }

    @ViewBuilder
    private var actions: some View {
        if isOwnRecipe {
            Text("This is your own recipe, so another admin has to review it.")
                .font(.outfit(size: 12))
                .foregroundStyle(Color.charcoalLight)
        } else {
            HStack(spacing: 8) {
                switch recipe.status {
                case .visible:
                    actionButton("Flag", filled: false, action: onFlag)
                    actionButton("Remove", filled: true, action: onRemove)
                case .flagged:
                    actionButton("Approve", filled: false, tint: Color.sage, action: onApprove)
                    actionButton("Remove", filled: true, action: onRemove)
                case .removed:
                    actionButton("Restore", filled: false, tint: Color.sage, action: onApprove)
                }
            }
            .disabled(isWorking)
        }
    }

    private func actionButton(_ title: String, filled: Bool, tint: Color = Color.terracotta, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.outfit(size: 13, weight: .semibold))
                .foregroundStyle(filled ? Color.white : tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(filled ? tint : Color.clear, in: Capsule())
                .overlay(Capsule().stroke(tint.opacity(filled ? 0 : 0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
