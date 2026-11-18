//
//  ModerationReasonSheet.swift
//  CookAI
//
//  Asks the admin for the reason before a recipe is flagged or removed. The
//  reason is required (the database enforces it too) and is shown to the
//  uploader in their notification.
//

import SwiftUI

struct ModerationReasonSheet: View {
    let recipeTitle: String
    let status: RecipeStatus
    let isWorking: Bool
    var errorMessage: String? = nil
    let onConfirm: (String) -> Void
    let onCancel: () -> Void

    @State private var reason = ""

    private var isRemoving: Bool { status == .removed }
    private var trimmedReason: String { reason.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var accent: Color { isRemoving ? Color(hex: "#9C2B2B") : Color(hex: "#B8860B") }

    private var presets: [String] {
        isRemoving
            ? ["Inappropriate content", "Unsafe cooking advice", "Spam or off-topic", "Repeated violations"]
            : ["Inaccurate quantities or steps", "Unverified health claim", "Photo isn't an original cook", "Duplicate submission"]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(Color.charcoal.opacity(0.15))
                .frame(width: 40, height: 4)
                .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                Image(systemName: isRemoving ? "trash" : "flag")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 36, height: 36)
                    .background(accent.opacity(0.14), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(isRemoving ? "Remove this recipe" : "Flag this recipe")
                        .font(.lora(size: 17, weight: .semibold))
                        .foregroundStyle(Color.charcoal)
                    Text(isRemoving
                         ? "This will hide the recipe from all users. The uploader is notified with your reason."
                         : "The uploader will be notified with your reason.")
                        .font(.outfit(size: 12))
                        .foregroundStyle(Color.charcoalLight)
                }
            }

            Text("“\(recipeTitle)”")
                .font(.outfit(size: 13, weight: .medium))
                .foregroundStyle(Color.charcoalMid)
                .lineLimit(2)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 2) {
                    Text("Reason")
                    Text("*").foregroundStyle(accent)
                }
                .font(.outfit(size: 13, weight: .semibold))
                .foregroundStyle(Color.charcoalMid)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.self) { preset in
                            CategoryChip(title: preset, isActive: reason == preset) {
                                reason = preset
                            }
                        }
                    }
                }

                TextField(isRemoving ? "Explain why you're removing this recipe…" : "Explain why you're flagging this recipe…",
                          text: $reason, axis: .vertical)
                    .font(.outfit(size: 14))
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))

                if trimmedReason.isEmpty {
                    Text("Required before confirming")
                        .font(.outfit(size: 11))
                        .foregroundStyle(Color.charcoalPale)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.outfit(size: 13))
                    .foregroundStyle(Color(hex: "#9C2B2B"))
            }

            HStack(spacing: 10) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.outfit(size: 15, weight: .semibold))
                        .foregroundStyle(Color.charcoalMid)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(Capsule().stroke(Color.creamBorder, lineWidth: 1.5))
                }
                .buttonStyle(.plain)

                Button {
                    onConfirm(trimmedReason)
                } label: {
                    HStack(spacing: 8) {
                        if isWorking { ProgressView().tint(.white) }
                        Text(isRemoving ? "Remove" : "Flag")
                            .font(.outfit(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(trimmedReason.isEmpty ? Color.charcoalPale : accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(trimmedReason.isEmpty || isWorking)
            }
        }
        .padding(20)
        .background(Color.cream.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }
}
