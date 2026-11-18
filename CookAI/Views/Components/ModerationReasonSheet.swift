//
//  ModerationReasonSheet.swift
//  CookAI
//
//  Asks the admin for the reason before a recipe is flagged or removed. The
//  reason is required (the database enforces it too) and is shown to the cook
//  in their notification.
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

            VStack(alignment: .leading, spacing: 4) {
                Text(isRemoving ? "Remove recipe" : "Flag recipe")
                    .font(.lora(size: 20, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                Text("“\(recipeTitle)”")
                    .font(.outfit(size: 13))
                    .foregroundStyle(Color.charcoalLight)
                    .lineLimit(2)
            }

            Text("The cook will see your reason in their notifications.")
                .font(.outfit(size: 13))
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

            TextField("Write the reason…", text: $reason, axis: .vertical)
                .font(.outfit(size: 14))
                .lineLimit(3...6)
                .padding(12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))

            if let errorMessage {
                Text(errorMessage)
                    .font(.outfit(size: 13))
                    .foregroundStyle(Color.terracottaDark)
            }

            HStack(spacing: 10) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.outfit(size: 15, weight: .semibold))
                        .foregroundStyle(Color.charcoalMid)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(Capsule().stroke(Color.creamBorder, lineWidth: 1))
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
                    .background(trimmedReason.isEmpty ? Color.charcoalPale : Color.terracotta, in: Capsule())
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
