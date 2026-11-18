//
//  NotificationsScreen.swift
//  CookAI
//
//  Ports the Notifications screen from the Figma prototype: a list of what
//  happened to your recipes (liked, saved, commented, cooked, or flagged /
//  removed by an admin with the reason). Unread rows are tinted with a dot;
//  tapping a row opens the recipe.
//

import SwiftUI

struct NotificationsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var controller = NotificationsController()

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

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            CustomBackButton { dismiss() }
            VStack(alignment: .leading, spacing: 2) {
                Text("Notifications")
                    .font(.lora(size: 20, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                if controller.unreadCount > 0 {
                    Text("\(controller.unreadCount) unread")
                        .font(.outfit(size: 12))
                        .foregroundStyle(Color.charcoalLight)
                }
            }
            Spacer()
            if controller.unreadCount > 0 {
                Button {
                    Task { await controller.markAllRead() }
                } label: {
                    Text("Mark all read")
                        .font(.outfit(size: 13, weight: .semibold))
                        .foregroundStyle(Color.terracotta)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if !controller.hasLoaded && controller.notifications.isEmpty {
            ProgressView().tint(Color.terracotta)
                .padding(.top, 64)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else if let message = controller.errorMessage, controller.notifications.isEmpty {
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
        } else if controller.notifications.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "bell")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.charcoalLight)
                    .frame(width: 64, height: 64)
                    .background(Color.charcoal.opacity(0.06), in: Circle())
                Text("No notifications yet")
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoalLight)
            }
            .padding(.top, 80)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(controller.notifications) { item in
                        row(item)
                        Divider().overlay(Color.creamBorder)
                    }
                }
            }
            .refreshable { await controller.load() }
        }
    }

    // MARK: - Row

    private func row(_ item: AppNotification) -> some View {
        Button {
            Task {
                if let recipe = await controller.open(item) {
                    router.push(.recipeOverview(recipe))
                }
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                avatar(for: item)
                VStack(alignment: .leading, spacing: 6) {
                    text(for: item)
                        .font(.outfit(size: 13))
                        .foregroundStyle(Color.charcoalMid)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        typeIcon(item.type)
                        Text(item.createdAt.formatted(.relative(presentation: .named)))
                            .font(.outfit(size: 11))
                            .foregroundStyle(Color.charcoalPale)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if !item.isRead {
                    Circle().fill(Color.terracotta).frame(width: 8, height: 8).padding(.top, 6)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(item.isRead ? Color.clear : Color.terracotta.opacity(0.04))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func avatar(for item: AppNotification) -> some View {
        let user = controller.sender(of: item)
        let isAdminEvent = item.type == .flagged || item.type == .removed
        return ZStack {
            Circle().fill(user.map { Color(hex: $0.avatarColorHex) } ?? Color.charcoalPale)
            if isAdminEvent {
                Image(systemName: "sparkle").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
            } else {
                Text(String((user?.displayName ?? "?").prefix(1)).uppercased())
                    .font(.lora(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 40, height: 40)
    }

    private func bold(_ s: String) -> Text {
        Text(s).font(.outfit(size: 13, weight: .semibold)).foregroundStyle(Color.charcoal)
    }

    private func text(for item: AppNotification) -> Text {
        let who = bold("@" + (controller.sender(of: item)?.username ?? "someone"))
        let recipe = bold(item.recipeName)
        switch item.type {
        case .cooked: return who + Text(" cooked your ") + recipe
        case .liked: return who + Text(" liked your recipe ") + recipe
        case .commented: return who + Text(" commented on ") + recipe
        case .saved: return who + Text(" saved your recipe ") + recipe
        case .flagged:
            let reason = item.adminReason.map {
                Text(": \"\($0)\"").foregroundStyle(Color(hex: "#B8860B"))
            } ?? Text("")
            return Text("Your recipe ") + recipe + Text(" was flagged") + reason
        case .removed:
            let reason = item.adminReason.map {
                Text(": \"\($0)\"").foregroundStyle(Color(hex: "#9C2B2B"))
            } ?? Text("")
            return Text("Your recipe ") + recipe + Text(" was removed") + reason
        }
    }

    private func typeIcon(_ type: NotificationType) -> some View {
        let (symbol, tint): (String, Color) = {
            switch type {
            case .cooked: return ("mappin.circle", Color.sage)
            case .liked: return ("heart.fill", Color.terracotta)
            case .commented: return ("bubble.left", Color.charcoalMid)
            case .saved: return ("bookmark", Color.sage)
            case .flagged: return ("flag", Color(hex: "#B8860B"))
            case .removed: return ("trash", Color(hex: "#9C2B2B"))
            }
        }()
        return Image(systemName: symbol)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: 26, height: 26)
            .background(tint.opacity(0.14), in: Circle())
    }
}

#Preview {
    NavigationStack { NotificationsScreen() }
        .environment(AppRouter())
}
