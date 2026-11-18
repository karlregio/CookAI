//
//  SupabaseAuthService.swift
//  CookAI
//
//  AuthService backed by Supabase Auth (email + password). The matching
//  `profiles` row is created by the `handle_new_user` database trigger, and
//  the role (standard/admin) is read from it — never decided by the app.
//

import Foundation
import Supabase

final class SupabaseAuthService: AuthService {
    private let client: SupabaseClient
    private(set) var currentUser: CookAIUser?

    init(client: SupabaseClient = SupabaseConfig.client) {
        self.client = client
    }

    func restoreSession() async -> CookAIUser? {
        do {
            let session = try await client.auth.session
            let user = try await fetchProfile(id: session.user.id)
            currentUser = user
            return user
        } catch {
            currentUser = nil
            return nil
        }
    }

    func signIn(email: String, password: String) async throws -> CookAIUser {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            throw AuthServiceError.invalidCredentials
        }
        do {
            let session = try await client.auth.signIn(email: trimmedEmail, password: password)
            let user = try await fetchProfile(id: session.user.id)
            currentUser = user
            return user
        } catch {
            throw Self.friendlyAuthError(error)
        }
    }

    func signUp(name: String, email: String, password: String) async throws -> CookAIUser {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty, !password.isEmpty else {
            throw AuthServiceError.signUpFailed
        }
        do {
            let response = try await client.auth.signUp(
                email: trimmedEmail,
                password: password,
                data: ["display_name": .string(trimmedName)]
            )
            // With "Confirm email" on, Supabase returns no session until the link is tapped.
            guard let session = response.session else {
                throw SupabaseServiceError.confirmEmail
            }
            let user = try await fetchProfile(id: session.user.id)
            currentUser = user
            return user
        } catch {
            throw Self.friendlyAuthError(error)
        }
    }

    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw SupabaseServiceError.friendly(error)
        }
        currentUser = nil
    }

    // MARK: - Helpers

    private func fetchProfile(id: UUID) async throws -> CookAIUser {
        let profiles: [CookAIUser] = try await client
            .from("profiles")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .fetch()
        guard let profile = profiles.first else {
            throw SupabaseServiceError.profileMissing
        }
        return profile
    }

    private static func friendlyAuthError(_ error: Error) -> Error {
        if error is SupabaseServiceError || error is AuthServiceError { return error }
        if error is URLError { return SupabaseServiceError.network }
        let message = error.localizedDescription.lowercased()
        if message.contains("invalid login") || message.contains("invalid credentials") {
            return AuthServiceError.invalidCredentials
        }
        if message.contains("email not confirmed") {
            return SupabaseServiceError.confirmEmail
        }
        // Supabase's own messages are readable ("User already registered",
        // "Password should be at least 6 characters"), so pass them through.
        return error
    }
}
