//
//  AskAISheet.swift
//  CookAI
//
//  Ports AskAIOverlay from App.tsx (~lines 2833–2964): a bottom sheet with
//  the current step as context, chat bubbles, quick-question chips, and an
//  input row. Purely presentational — driven by CookSessionController's
//  chat history and AIService-backed responses.
//

import SwiftUI

struct AskAISheet: View {
    let currentStepText: String
    let messages: [AIChatMessage]
    @Binding var inputText: String
    let isSending: Bool
    let errorMessage: String?
    let onSend: (String) -> Void
    let onClose: () -> Void

    private let quickQuestions = ["I'm running late", "Substitute an ingredient", "This doesn't look right"]

    var body: some View {
        VStack(spacing: 0) {
            handle
            header
            chatList
            if let errorMessage {
                Text(errorMessage)
                    .font(.outfit(size: 12))
                    .foregroundStyle(Color.terracottaDark)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)
            }
            quickQuestionRow
            inputRow
        }
        .background(Color.cream.ignoresSafeArea())
    }

    private var handle: some View {
        Capsule()
            .fill(Color.charcoal.opacity(0.15))
            .frame(width: 40, height: 4)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Ask AI")
                    .font(.lora(size: 18, weight: .semibold))
                    .foregroundStyle(Color.charcoal)

                HStack(spacing: 4) {
                    Text("📍")
                    Text(currentStepText)
                        .lineLimit(1)
                }
                .font(.outfit(size: 11, weight: .semibold))
                .foregroundStyle(Color.sage)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.sage.opacity(0.15), in: Capsule())
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.charcoalLight)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var chatList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(messages) { message in
                    chatBubble(message)
                }
                if isSending {
                    typingIndicator
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }

    private func chatBubble(_ message: AIChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            Text(message.text)
                .font(.outfit(size: 14))
                .foregroundStyle(message.role == .user ? .white : Color.charcoal)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    message.role == .user ? Color.terracotta : Color.white,
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(message.role == .assistant ? Color.creamBorder : .clear, lineWidth: 1)
                )

            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color.charcoalLight)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))

            Spacer(minLength: 40)
        }
    }

    private var quickQuestionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickQuestions, id: \.self) { question in
                    Button {
                        onSend(question)
                    } label: {
                        Text(question)
                            .font(.outfit(size: 12, weight: .medium))
                            .foregroundStyle(Color.charcoalMid)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white, in: Capsule())
                            .overlay(Capsule().stroke(Color.creamBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSending)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 8)
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("Ask anything about this step...", text: $inputText)
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoal)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white, in: Capsule())
                .overlay(Capsule().stroke(Color.creamBorder, lineWidth: 1))
                .onSubmit { onSend(inputText) }

            Button {
                onSend(inputText)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.terracotta, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 20)
    }
}

private struct AskAISheetPreview: View {
    @State private var text = ""

    var body: some View {
        AskAISheet(
            currentStepText: "Simmer the sauce for 10 minutes",
            messages: [
                AIChatMessage(id: UUID(), role: .user, text: "What can I substitute for heavy cream?", createdAt: Date()),
                AIChatMessage(id: UUID(), role: .assistant, text: "Try half-and-half or full-fat coconut milk for a richer flavor.", createdAt: Date()),
            ],
            inputText: $text,
            isSending: false,
            errorMessage: nil,
            onSend: { _ in },
            onClose: {}
        )
    }
}

#Preview {
    AskAISheetPreview()
}
