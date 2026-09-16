//
//  SwapIngredientSheet.swift
//  CookAI
//
//  Ports SwapIngredientSheet from App.tsx (~lines 1422–1574): a bottom sheet
//  that asks "What do you have instead?", calls the AI for a substitution
//  suggestion (with a loading state), and lets the user confirm the swap.
//  Purely presentational — all state/network calls live in whichever
//  controller drives it (RecipeOverviewController today).
//

import SwiftUI

struct SwapIngredientSheet: View {
    let ingredientName: String
    @Binding var inputText: String
    let isLoading: Bool
    let suggestion: SubstitutionSuggestion?
    let errorMessage: String?
    let onAsk: () -> Void
    let onConfirm: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(alignment: .leading, spacing: 0) {
                Capsule()
                    .fill(Color.charcoal.opacity(0.15))
                    .frame(width: 40, height: 4)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                header
                inputRow

                if isLoading {
                    loadingRow
                } else if let errorMessage {
                    Text(errorMessage)
                        .font(.outfit(size: 12))
                        .foregroundStyle(Color.terracottaDark)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                } else if let suggestion {
                    suggestionCard(suggestion)
                }
            }
            .padding(.bottom, 32)
            .background(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28).fill(Color.cream))
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Swap Ingredient")
                    .font(.lora(size: 18, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                Text(replacingLabel)
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundStyle(Color.charcoalLight)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var replacingLabel: AttributedString {
        var prefix = AttributedString("Replacing: ")
        prefix.font = .outfit(size: 12)
        prefix.foregroundColor = Color.charcoalLight

        var name = AttributedString(ingredientName)
        name.font = .outfit(size: 12, weight: .medium)
        name.foregroundColor = Color.charcoalMid

        prefix.append(name)
        return prefix
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("What do you have instead?", text: $inputText)
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoal)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))
                .onSubmit(onAsk)

            Button(action: onAsk) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.terracotta, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal, 20)
    }

    private var loadingRow: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text("Finding the best substitute...")
                .font(.outfit(size: 13))
                .foregroundStyle(Color.charcoalLight)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private func suggestionCard(_ suggestion: SubstitutionSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("✦").foregroundStyle(Color.terracotta)
                Text("AI SUGGESTION")
                    .font(.outfit(size: 11, weight: .semibold))
                    .foregroundStyle(Color.terracotta)
                    .tracking(0.5)
            }

            Text(suggestion.replacement)
                .font(.outfit(size: 14, weight: .semibold))
                .foregroundStyle(Color.charcoal)

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.sage)
                Text(suggestion.note)
                    .font(.outfit(size: 12))
                    .foregroundStyle(Color.charcoalMid)
            }
            .padding(10)
            .background(Color.sage.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button(action: onConfirm) {
                Text("Use this swap")
                    .font(.outfit(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.terracotta, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

private struct SwapIngredientSheetPreview: View {
    @State private var text = ""

    var body: some View {
        SwapIngredientSheet(
            ingredientName: "Spaghetti",
            inputText: $text,
            isLoading: false,
            suggestion: SubstitutionSuggestion(id: UUID(), originalIngredient: "Spaghetti", replacement: "Linguine or fettuccine", note: "Same cook time. Wider noodles will hold slightly more sauce."),
            errorMessage: nil,
            onAsk: {},
            onConfirm: {},
            onClose: {}
        )
    }
}

#Preview {
    SwapIngredientSheetPreview()
}
