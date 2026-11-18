//
//  ServiceContainer.swift
//  CookAI
//
//  Single place where concrete service implementations are wired up. Auth,
//  recipes and notifications use Supabase; AI is still the mock until the
//  Gemini Edge Function is in place. Callers depend only on the protocols.
//

import SwiftUI

final class ServiceContainer {
    static let shared = ServiceContainer()

    let authService: AuthService
    let recipeRepository: RecipeRepository
    let aiService: AIService
    let notificationService: NotificationService

    init(
        authService: AuthService = SupabaseAuthService(),
        recipeRepository: RecipeRepository = SupabaseRecipeRepository(),
        aiService: AIService = MockAIService(),
        notificationService: NotificationService = SupabaseNotificationService()
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
