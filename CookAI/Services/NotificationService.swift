//
//  NotificationService.swift
//  CookAI
//
//  Protocol + mock implementation for the notification-count badge shown on
//  the dashboard. The full Notifications feature itself is finals-only (see
//  PROJECT_RULES.md #6) — this only exposes the unread count needed for the
//  bell badge today.
//

import Foundation

protocol NotificationService: AnyObject {
    func fetchUnreadCount() async throws -> Int
    /// The signed-in user's notifications, newest first (guests get none).
    func fetchNotifications() async throws -> [AppNotification]
    /// Marks every unread notification as read.
    func markAllRead() async throws
    /// Marks a single notification as read.
    func markRead(id: UUID) async throws
}

final class MockNotificationService: NotificationService {
    private var items = MockData.notifications

    private func simulateNetworkDelay() async throws {
        try await Task.sleep(for: .seconds(Double.random(in: 0.3...0.7)))
    }

    func fetchUnreadCount() async throws -> Int {
        try await simulateNetworkDelay()
        return items.filter { !$0.isRead }.count
    }

    func fetchNotifications() async throws -> [AppNotification] {
        try await simulateNetworkDelay()
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    func markAllRead() async throws {
        try await simulateNetworkDelay()
        for index in items.indices { items[index].isRead = true }
    }

    func markRead(id: UUID) async throws {
        try await simulateNetworkDelay()
        if let index = items.firstIndex(where: { $0.id == id }) { items[index].isRead = true }
    }
}
