//
//  PostCookReflectionSheet.swift
//  CookAI
//
//  Ports the Post-Cook Reflection sheet inside CookModeScreen (App.tsx
//  ~lines 2767–2826): a star picker, an optional "what went wrong" section,
//  and a submit/skip footer. Deviates from the prototype on purpose — the
//  issue text is actually sent to AIService.troubleshoot with a real
//  response shown inline, rather than being collected and discarded.
//

import SwiftUI

struct PostCookReflectionSheet: View {
    @Binding var rating: Int
    @Binding var issueText: String
    let troubleshootResponse: String?
    let isTroubleshooting: Bool
    let isSubmitting: Bool
    let onSubmitIssue: () -> Void
    let onFinish: () -> Void
    let onSkip: () -> Void

    private let ratingLabels = ["", "Not great", "Needs work", "It was okay", "Pretty good", "Absolutely loved it"]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.charcoal.opacity(0.15))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                Text("🍽").font(.system(size: 32))

                Text("How did it turn out?")
                    .font(.lora(size: 20, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                    .padding(.top, 6)

                Text("Your rating helps the community")
                    .font(.outfit(size: 13))
                    .foregroundStyle(Color.charcoalLight)
                    .padding(.top, 2)
                    .padding(.bottom, 20)

                StarPicker(value: $rating, size: 40)

                if rating > 0 {
                    Text(ratingLabels[rating])
                        .font(.outfit(size: 14, weight: .semibold))
                        .foregroundStyle(Color.starGold)
                        .padding(.top, 10)
                }

                if rating > 0 && rating <= 3 {
                    issueSection
                }

                Button(action: onFinish) {
                    HStack(spacing: 8) {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        }
                        Text(rating > 0 ? "Submit & Finish" : "Finish without rating")
                    }
                    .font(.outfit(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(rating > 0 ? Color.starGold : Color.terracotta, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isSubmitting)
                .padding(.top, 22)

                if rating == 0 {
                    Button("Skip", action: onSkip)
                        .font(.outfit(size: 14))
                        .foregroundStyle(Color.charcoalLight)
                        .buttonStyle(.plain)
                        .disabled(isSubmitting)
                        .padding(.top, 10)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.cream)
    }

    private var issueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What went wrong? (optional)")
                .font(.outfit(size: 13, weight: .medium))
                .foregroundStyle(Color.charcoalMid)

            TextField("Describe the issue — our AI will note it for future improvements", text: $issueText, axis: .vertical)
                .font(.outfit(size: 13))
                .foregroundStyle(Color.charcoal)
                .lineLimit(3, reservesSpace: true)
                .padding(10)
                .background(Color(hex: "#F5EFE8"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))

            if isTroubleshooting {
                HStack(spacing: 6) {
                    ProgressView()
                    Text("Getting AI feedback...")
                        .font(.outfit(size: 12))
                        .foregroundStyle(Color.charcoalLight)
                }
            } else if let troubleshootResponse {
                HStack(alignment: .top, spacing: 6) {
                    Text("✦").foregroundStyle(Color.sage)
                    Text(troubleshootResponse)
                        .font(.outfit(size: 12))
                        .foregroundStyle(Color.charcoalMid)
                }
                .padding(10)
                .background(Color.sage.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Button("Get AI feedback", action: onSubmitIssue)
                    .font(.outfit(size: 12, weight: .semibold))
                    .foregroundStyle(Color.sage)
                    .buttonStyle(.plain)
                    .disabled(issueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
    }
}

private struct PostCookReflectionSheetPreview: View {
    @State private var rating = 2
    @State private var issue = ""

    var body: some View {
        PostCookReflectionSheet(
            rating: $rating,
            issueText: $issue,
            troubleshootResponse: nil,
            isTroubleshooting: false,
            isSubmitting: false,
            onSubmitIssue: {},
            onFinish: {},
            onSkip: {}
        )
    }
}

#Preview {
    PostCookReflectionSheetPreview()
}
