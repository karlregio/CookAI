//
//  AuthService.swift
//  CookAI
//
//  Protocol + mock implementation. A Supabase-backed implementation will
//  conform to the same protocol later without any caller changes.
//

import Foundation

protocol AuthService: AnyObject {
    var currentUser: User? { get }
    /// Restores a saved login from a previous launch, if any.
    func restoreSession() async -> User?
    func signIn(email: String, password: String) async throws -> User
    func signUp(name: String, email: String, password: String) async throws -> User
    func signOut() async throws
}

enum AuthServiceError: LocalizedError {
    case invalidCredentials
    case signUpFailed

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Enter a valid email and password to continue."
        case .signUpFailed:
            return "Couldn't create your account. Please check your details and try again."
        }
    }
}

final class MockAuthService: AuthService {
    private(set) var currentUser: User?

    private func simulateNetworkDelay() async throws {
        try await Task.sleep(for: .seconds(Double.random(in: 0.6...1.5)))
    }

    func restoreSession() async -> User? {
        currentUser
    }

    /// Mock rule: "admin@cookai.com" (case-insensitive) signs in as the admin account;
    /// any other non-empty email/password signs in as Alex.
    func signIn(email: String, password: String) async throws -> User {
        try await simulateNetworkDelay()
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            throw AuthServiceError.invalidCredentials
        }
        let user = trimmedEmail.caseInsensitiveCompare("admin@cookai.com") == .orderedSame
            ? MockData.adminUser
            : MockData.alexUser
        currentUser = user
        return user
    }

    func signUp(name: String, email: String, password: String) async throws -> User {
        try await simulateNetworkDelay()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty, !password.isEmpty else {
            throw AuthServiceError.signUpFailed
        }
        var user = MockData.alexUser
        user.displayName = trimmedName
        user.email = trimmedEmail
        currentUser = user
        return user
    }

    func signOut() async throws {
        try await Task.sleep(for: .seconds(0.4))
        currentUser = nil
    }
}
