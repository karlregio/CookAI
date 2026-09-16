//
//  RateRecipeSheet.swift
//  CookAI
//
//  Ports the "Rate this Recipe" sheet from App.tsx (~lines 2330–2369): a
//  tappable star picker with a submit button. Purely presentational.
//

import SwiftUI

struct RateRecipeSheet: View {
    let currentAverage: Double
    let currentCount: Int
    @Binding var selectedRating: Int
    let isSubmitting: Bool
    let onSubmit: () -> Void
    let onCancel: () -> Void

    private let ratingLabels = ["", "Not great", "Needs work", "It was okay", "Pretty good", "Absolutely loved it"]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.charcoal.opacity(0.15))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                Text("Rate this Recipe")
                    .font(.lora(size: 18, weight: .semibold))
                    .foregroundStyle(Color.charcoal)

                Text("Currently \(String(format: "%.1f", currentAverage)) · \(currentCount.formatted()) ratings")
                    .font(.outfit(size: 13))
                    .foregroundStyle(Color.charcoalLight)

                StarPicker(value: $selectedRating, size: 36)
                    .padding(.vertical, 4)

                if selectedRating > 0 {
                    Text(ratingLabels[selectedRating])
                        .font(.outfit(size: 14, weight: .semibold))
                        .foregroundStyle(Color.starGold)
                }

                Button(action: onSubmit) {
                    HStack(spacing: 8) {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        }
                        Text(selectedRating > 0 ? "Submit Rating" : "Tap a star to rate")
                    }
                    .font(.outfit(size: 14, weight: .semibold))
                    .foregroundStyle(selectedRating > 0 ? .white : Color.charcoalLight)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        selectedRating > 0 ? Color.starGold : Color.charcoal.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .disabled(selectedRating == 0 || isSubmitting)

                Button("Cancel", action: onCancel)
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoalLight)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28).fill(Color.cream))
        }
    }
}

private struct RateRecipeSheetPreview: View {
    @State private var rating = 0

    var body: some View {
        RateRecipeSheet(
            currentAverage: 4.7,
            currentCount: 214,
            selectedRating: $rating,
            isSubmitting: false,
            onSubmit: {},
            onCancel: {}
        )
    }
}

#Preview {
    RateRecipeSheetPreview()
}
