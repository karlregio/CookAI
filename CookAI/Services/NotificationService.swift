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
}

final class MockNotificationService: NotificationService {
    private func simulateNetworkDelay() async throws {
        try await Task.sleep(for: .seconds(Double.random(in: 0.3...0.7)))
    }

    func fetchUnreadCount() async throws -> Int {
        try await simulateNetworkDelay()
        return MockData.notifications.filter { !$0.isRead }.count
    }
}
