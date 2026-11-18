//
//  AdminComponents.swift
//  CookAI
//
//  Small pieces shared by the three admin screens: the ADMIN badge, the
//  status pill, the message banner and the admin header.
//

import SwiftUI

/// The orange "ADMIN" tag next to admin screen titles.
struct AdminBadge: View {
    var text = "ADMIN"

    var body: some View {
        Text(text)
            .font(.outfit(size: 10, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.terracotta, in: Capsule())
    }
}

/// "✓ Visible", "🚩 Flagged" or "✕ Removed".
struct AdminStatusPill: View {
    let status: RecipeStatus

    var body: some View {
        Text(label)
            .font(.outfit(size: 10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .fixedSize()
    }

    private var label: String {
        switch status {
        case .visible: return "✓ Visible"
        case .flagged: return "🚩 Flagged"
        case .removed: return "✕ Removed"
        }
    }

    private var color: Color {
        switch status {
        case .visible: return Color.sage
        case .flagged: return Color.terracotta
        case .removed: return Color.charcoalLight
        }
    }
}

/// A dismissible success or error message.
struct AdminMessageBanner: View {
    let text: String
    let color: Color
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(text)
                .font(.outfit(size: 13))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Back button + title + ADMIN badge, shared by the admin screens.
struct AdminHeader: View {
    let title: String
    var subtitle: String?
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CustomBackButton(action: onBack)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.lora(size: 22, weight: .semibold))
                        .foregroundStyle(Color.charcoal)
                    AdminBadge()
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.outfit(size: 12))
                        .foregroundStyle(Color.charcoalLight)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
}
