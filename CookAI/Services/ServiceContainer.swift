//
//  ServiceContainer.swift
//  CookAI
//
//  Single place where concrete service implementations are wired up. Auth,
//  recipes, notifications and AI (Gemini via an Edge Function) use Supabase.
//  The Mock* services remain for previews and tests. Callers depend only on the protocols.
//

import SwiftUI

final class ServiceContainer {
    static let shared = ServiceContainer()

    let authService: AuthService
    let recipeRepository: RecipeRepository
    let aiService: AIService
    let notificationService: NotificationService
    let messageService: MessageService
    let groceryService: GroceryService

    init(
        authService: AuthService = SupabaseAuthService(),
        recipeRepository: RecipeRepository = SupabaseRecipeRepository(),
        aiService: AIService = SupabaseAIService(),
        notificationService: NotificationService = SupabaseNotificationService(),
        messageService: MessageService = SupabaseMessageService(),
        groceryService: GroceryService = SupabaseGroceryService()
    ) {
        self.authService = authService
        self.recipeRepository = recipeRepository
        self.aiService = aiService
        self.notificationService = notificationService
        self.messageService = messageService
        self.groceryService = groceryService
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
