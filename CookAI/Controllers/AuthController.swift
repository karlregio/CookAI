//
//  AuthController.swift
//  CookAI
//
//  Handles the sign-in/sign-up/sign-out user actions for LoginScreen (and
//  later Profile) against AuthService from the ServiceContainer.
//

import Foundation
import Observation

@Observable
final class AuthController {
    private let authService: AuthService

    private(set) var currentUser: User?
    var isLoading = false
    var errorMessage: String?

    /// Invoked after a successful sign-out so the app can return to the login screen.
    var onSignedOut: (() -> Void)?

    init(services: ServiceContainer = .shared) {
        self.authService = services.authService
        self.currentUser = services.authService.currentUser
    }

    /// Called once at launch so a returning user skips the login screen.
    func restoreSession() async {
        if let restored = await authService.restoreSession() {
            currentUser = restored
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            currentUser = try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(name: String, email: String, password: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            currentUser = try await authService.signUp(name: name, email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.signOut()
            currentUser = nil
            onSignedOut?()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
