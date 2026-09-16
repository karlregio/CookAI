//
//  ServiceContainer.swift
//  CookAI
//
//  Single place where concrete service implementations are wired up. Swap the
//  Mock* implementations for Supabase-backed ones here once the backend is
//  ready — no caller code needs to change since everything depends on the
//  protocols, not the concrete types.
//

import SwiftUI

final class ServiceContainer {
    static let shared = ServiceContainer()

    let authService: AuthService
    let recipeRepository: RecipeRepository
    let aiService: AIService
    let notificationService: NotificationService

    init(
        authService: AuthService = MockAuthService(),
        recipeRepository: RecipeRepository = MockRecipeRepository(),
        aiService: AIService = MockAIService(),
        notificationService: NotificationService = MockNotificationService()
    ) {
        self.authService = authService
        self.recipeRepository = recipeRepository
        self.aiService = aiService
        self.notificationService = notificationService
    }
}

private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    var services: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
