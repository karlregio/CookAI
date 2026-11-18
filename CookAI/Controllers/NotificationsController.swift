//
//  NotificationsController.swift
//  CookAI
//
//  Notifications screen: loads the signed-in user's notifications (likes,
//  comments, saves, cooks, and admin flags/removals with the reason), looks up
//  who each one is from, and marks them read.
//

import Foundation
import Observation

@Observable
final class NotificationsController {
    private let notificationService: NotificationService
    private let recipeRepository: RecipeRepository

    private(set) var notifications: [AppNotification] = []
    private(set) var people: [UUID: User] = [:]
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    init(services: ServiceContainer = .shared) {
        self.notificationService = services.notificationService
        self.recipeRepository = services.recipeRepository
    }

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    func sender(of notification: AppNotification) -> User? { people[notification.fromUserId] }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false; hasLoaded = true }
        do {
            let loaded = try await notificationService.fetchNotifications()
            let ids = Array(Set(loaded.map(\.fromUserId)))
            let users = try await recipeRepository.fetchUsers(ids: ids)
            notifications = loaded
            people = Dictionary(users.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markAllRead() async {
        let previous = notifications
        for index in notifications.indices { notifications[index].isRead = true }
        do {
            try await notificationService.markAllRead()
        } catch {
            notifications = previous
            errorMessage = error.localizedDescription
        }
    }

    /// Marks the notification read and returns its recipe (nil if it no longer exists).
    func open(_ notification: AppNotification) async -> Recipe? {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }), !notifications[index].isRead {
            notifications[index].isRead = true
            try? await notificationService.markRead(id: notification.id)
        }
        do {
            return try await recipeRepository.fetchRecipe(id: notification.recipeId)
        } catch {
            errorMessage = "That recipe is no longer available."
            return nil
        }
    }
}
