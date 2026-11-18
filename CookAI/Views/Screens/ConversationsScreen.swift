//
//  ConversationsScreen.swift
//  CookAI
//
//  Ports the Messages list from the Figma prototype: your conversations with
//  avatar, @username, last message, time and an unread badge, plus search.
//

import SwiftUI

struct ConversationsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var controller = ConversationsController()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color.creamBorder)
            content
        }
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { Task { await controller.load() } }
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                CustomBackButton { dismiss() }
                Text("Messages")
                    .font(.lora(size: 20, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                if controller.totalUnread > 0 {
                    Text("\(controller.totalUnread)")
                        .font(.outfit(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(Color.terracotta, in: Circle())
                }
                Spacer()
            }
            SearchBar(text: $controller.searchText, placeholder: "Search conversations...")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var content: some View {
        if !controller.hasLoaded && controller.conversations.isEmpty {
            ProgressView().tint(Color.terracotta)
                .padding(.top, 64)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else if let message = controller.errorMessage, controller.conversations.isEmpty {
            VStack(spacing: 12) {
                Text(message)
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoalLight)
                    .multilineTextAlignment(.center)
                Button("Retry") { Task { await controller.load() } }
                    .font(.outfit(size: 14, weight: .semibold))
                    .foregroundStyle(Color.terracotta)
            }
            .padding(.top, 64)
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else if controller.shown.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.charcoalLight)
                    .frame(width: 64, height: 64)
                    .background(Color.charcoal.opacity(0.06), in: Circle())
                Text(controller.conversations.isEmpty ? "No messages yet" : "No conversations match")
                    .font(.outfit(size: 14, weight: .semibold))
                    .foregroundStyle(Color.charcoalMid)
                if controller.conversations.isEmpty {
                    Text("Open a cook's profile and tap Message to start chatting.")
                        .font(.outfit(size: 13))
                        .foregroundStyle(Color.charcoalLight)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .padding(.top, 80)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(controller.shown) { conversation in
                        row(conversation)
                        Divider().overlay(Color.creamBorder)
                    }
                }
            }
            .refreshable { await controller.load() }
        }
    }

    @ViewBuilder
    private func row(_ conversation: Conversation) -> some View {
        let user = controller.person(in: conversation)
        let unread = conversation.unreadCount > 0
        Button {
            if let user { router.push(.chat(conversation, user)) }
        } label: {
            HStack(spacing: 16) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle().fill(user.map { Color(hex: $0.avatarColorHex) } ?? Color.charcoalPale)
                        Text(String((user?.displayName ?? "?").prefix(1)).uppercased())
                            .font(.lora(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 48, height: 48)
                    if unread {
                        Text("\(conversation.unreadCount)")
                            .font(.outfit(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.terracotta, in: Circle())
                            .offset(x: 2, y: -2)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("@\(user?.username ?? "unknown")")
                            .font(.outfit(size: 14, weight: unread ? .semibold : .medium))
                            .foregroundStyle(unread ? Color.charcoal : Color.charcoalMid)
                        Spacer()
                        Text(conversation.lastMessageAt.formatted(.relative(presentation: .named)))
                            .font(.outfit(size: 11))
                            .foregroundStyle(Color.charcoalPale)
                    }
                    Text(conversation.lastMessage)
                        .font(.outfit(size: 13, weight: unread ? .medium : .regular))
                        .foregroundStyle(unread ? Color.charcoalMid : Color.charcoalLight)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { ConversationsScreen() }
        .environment(AppRouter())
}
