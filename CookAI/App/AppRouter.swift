//
//  AppRouter.swift
//  CookAI
//
//  App-wide navigation/session state. Grows into full screen routing as more
//  screens are added; for now it just tracks the signed-in user so RootView
//  can react to auth state changes.
//

import Observation

@Observable
final class AppRouter {
    private(set) var currentUser: User?

    private let authService: AuthService

    init(services: ServiceContainer = .shared) {
        self.authService = services.authService
        self.currentUser = services.authService.currentUser
    }

    func refreshSession() {
        currentUser = authService.currentUser
    }
}
