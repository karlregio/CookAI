//
//  ChatScreen.swift
//  CookAI
//
//  Ports the Chat screen from the Figma prototype: header with the other
//  cook, terracotta bubbles for you, white bubbles for them, day separators
//  and a message input bar. New replies appear automatically every few
//  seconds while the chat is open.
//

import SwiftUI

struct ChatScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var controller: ChatController
    @FocusState private var inputFocused: Bool

    init(conversation: Conversation, other: User) {
        _controller = State(initialValue: ChatController(conversation: conversation, other: other))
    }

    private var tint: Color { Color(hex: controller.other.avatarColorHex) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color.creamBorder)
            messagesList
        }
        .background(Color.cream.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { inputBar }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await controller.load()
            // Quietly pick up replies while the chat is open.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(4))
                if Task.isCancelled { break }
                await controller.refresh()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            CustomBackButton { dismiss() }
            Button {
                router.push(.cookProfile(controller.other))
            } label: {
                HStack(spacing: 10) {
                    avatar(size: 36, font: 14)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(controller.other.displayName)
                            .font(.outfit(size: 15, weight: .semibold))
                            .foregroundStyle(Color.charcoal)
                            .lineLimit(1)
                        Text("@\(controller.other.username)")
                            .font(.outfit(size: 11))
                            .foregroundStyle(Color.charcoalLight)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(Color.white.opacity(0.9))
    }

    private func avatar(size: CGFloat, font: CGFloat) -> some View {
        ZStack {
            Circle().fill(tint)
            Text(String(controller.other.displayName.prefix(1)).uppercased())
                .font(.lora(size: font, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Messages

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if !controller.hasLoaded {
                        ProgressView().tint(Color.terracotta).padding(.top, 40)
                    } else if controller.messages.isEmpty {
                        VStack(spacing: 6) {
                            Text("👋").font(.system(size: 32))
                            Text("Say hi to @\(controller.other.username)")
                                .font(.outfit(size: 14))
                                .foregroundStyle(Color.charcoalLight)
                        }
                        .padding(.top, 60)
                    }
                    ForEach(Array(controller.messages.enumerated()), id: \.element.id) { index, message in
                        if index == 0 || !Calendar.current.isDate(controller.messages[index - 1].sentAt, inSameDayAs: message.sentAt) {
                            daySeparator(message.sentAt)
                        }
                        bubble(message).id(message.id)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: controller.messages.count) {
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: controller.hasLoaded) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private func daySeparator(_ date: Date) -> some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.creamBorder).frame(height: 1)
            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.outfit(size: 11))
                .foregroundStyle(Color.charcoalPale)
            Rectangle().fill(Color.creamBorder).frame(height: 1)
        }
        .padding(.vertical, 4)
    }

    private func bubble(_ message: DirectMessage) -> some View {
        let mine = controller.isMine(message)
        return HStack(alignment: .bottom, spacing: 8) {
            if mine { Spacer(minLength: 48) } else { avatar(size: 28, font: 11) }
            VStack(alignment: mine ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.outfit(size: 14))
                    .foregroundStyle(mine ? Color.white : Color.charcoal)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: mine ? 18 : 5,
                            bottomTrailingRadius: mine ? 5 : 18,
                            topTrailingRadius: 18,
                            style: .continuous
                        )
                        .fill(mine ? Color.terracotta : Color.white)
                    )
                    .overlay {
                        if !mine {
                            UnevenRoundedRectangle(
                                topLeadingRadius: 18, bottomLeadingRadius: 5,
                                bottomTrailingRadius: 18, topTrailingRadius: 18,
                                style: .continuous
                            )
                            .stroke(Color.charcoal.opacity(0.1), lineWidth: 1)
                        }
                    }
                Text(message.sentAt.formatted(date: .omitted, time: .shortened))
                    .font(.outfit(size: 10))
                    .foregroundStyle(Color.charcoalPale)
            }
            if !mine { Spacer(minLength: 48) }
        }
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }

    // MARK: - Input

    private var inputBar: some View {
        VStack(spacing: 6) {
            if let message = controller.errorMessage, controller.hasLoaded {
                Text(message)
                    .font(.outfit(size: 12))
                    .foregroundStyle(Color(hex: "#9C2B2B"))
            }
            HStack(spacing: 10) {
                TextField("Type a message...", text: $controller.draft, axis: .vertical)
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoal)
                    .lineLimit(1...4)
                    .focused($inputFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.cream, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))

                Button {
                    Task { await controller.send() }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(controller.canSend ? Color.terracotta : Color.charcoalPale, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!controller.canSend)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
        .overlay(alignment: .top) { Divider().overlay(Color.creamBorder) }
    }
}

#Preview {
    NavigationStack {
        ChatScreen(conversation: MockData.conversations[0], other: MockData.naomiCooks)
    }
    .environment(AppRouter())
}
