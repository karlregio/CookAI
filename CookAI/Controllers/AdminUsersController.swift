//
//  AdminUsersController.swift
//  CookAI
//
//  The Users screen (opened from the "Total Users" card): every account with
//  its email (admins only), role, recipe count and join date, plus search and
//  an All / Admins / Cooks filter.
//

import Foundation
import Observation

@Observable
final class AdminUsersController {
    enum RoleFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case admins = "Admins"
        case cooks = "Cooks"

        var id: String { rawValue }

        func includes(_ user: User) -> Bool {
            switch self {
            case .all: return true
            case .admins: return user.role == .admin
            case .cooks: return user.role == .standard
            }
        }
    }

    private let recipeRepository: RecipeRepository
    private let authService: AuthService

    private(set) var users: [User] = []
    private(set) var emails: [UUID: String] = [:]
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    var searchText = ""
    var selectedFilter: RoleFilter = .all

    init(services: ServiceContainer = .shared) {
        self.recipeRepository = services.recipeRepository
        self.authService = services.authService
    }

    var isAdmin: Bool { authService.currentUser?.role == .admin }

    func count(for filter: RoleFilter) -> Int {
        users.filter { filter.includes($0) }.count
    }

    var shownUsers: [User] {
        let byRole = users.filter { selectedFilter.includes($0) }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return byRole }
        return byRole.filter { user in
            user.username.localizedCaseInsensitiveContains(query)
                || user.displayName.localizedCaseInsensitiveContains(query)
                || (emails[user.id]?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    func email(for user: User) -> String? { emails[user.id] }

    func isCurrentUser(_ user: User) -> Bool { user.id == authService.currentUser?.id }

    func load() async {
        guard isAdmin else {
            errorMessage = "Only admins can see the user list."
            return
        }
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasLoaded = true
        }
        do {
            let everyone = try await recipeRepository.fetchAllUsers()
            let found = try await recipeRepository.fetchUserEmails(ids: everyone.map(\.id))
            users = everyone
            emails = found
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
