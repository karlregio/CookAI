//
//  AdminUsersScreen.swift
//  CookAI
//
//  Users (opened from the dashboard's "Total Users" card): everyone with an
//  account, searchable by name or email, filterable by role. Tapping a person
//  opens Recipe Management filtered to their recipes.
//

import SwiftUI

struct AdminUsersScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var controller = AdminUsersController()

    var body: some View {
        VStack(spacing: 0) {
            AdminHeader(title: "Users", subtitle: subtitle) { dismiss() }
            searchAndFilters
            Divider().overlay(Color.creamBorder)
            content
        }
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { Task { await controller.load() } }
    }

    private var subtitle: String {
        let total = controller.users.count
        return "\(total) account\(total == 1 ? "" : "s")"
    }

    // MARK: - Search + filters

    private var searchAndFilters: some View {
        VStack(alignment: .leading, spacing: 12) {
            SearchBar(text: $controller.searchText, placeholder: "Search by name or email...")

            HStack(spacing: 8) {
                ForEach(AdminUsersController.RoleFilter.allCases) { filter in
                    CategoryChip(
                        title: "\(filter.rawValue) \(controller.count(for: filter))",
                        isActive: controller.selectedFilter == filter
                    ) {
                        controller.selectedFilter = filter
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    // MARK: - List

    @ViewBuilder
    private var content: some View {
        if !controller.hasLoaded && controller.users.isEmpty {
            ProgressView()
                .tint(Color.terracotta)
                .padding(.top, 64)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else if let message = controller.errorMessage, controller.users.isEmpty {
            errorState(message)
        } else if controller.shownUsers.isEmpty {
            VStack(spacing: 8) {
                Text("🔍").font(.system(size: 36))
                Text("No users match your search")
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoalLight)
            }
            .padding(.top, 64)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(controller.shownUsers) { user in
                        row(user)
                    }
                }
                .padding(.bottom, 24)
            }
            .refreshable { await controller.load() }
        }
    }

    private func row(_ user: User) -> some View {
        VStack(spacing: 0) {
            Button {
                router.push(.adminRecipes(status: nil, search: user.username))
            } label: {
                HStack(spacing: 12) {
                    avatar(user)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("@\(user.username)")
                                .font(.outfit(size: 14, weight: .semibold))
                                .foregroundStyle(Color.charcoal)
                                .lineLimit(1)
                            if user.role == .admin { AdminBadge() }
                            if controller.isCurrentUser(user) { youTag }
                        }
                        Text(controller.email(for: user) ?? "Email unavailable")
                            .font(.outfit(size: 12))
                            .foregroundStyle(Color.charcoalLight)
                            .lineLimit(1)
                        if let joined = user.createdAt {
                            Text("Joined \(joined.formatted(.dateTime.month(.abbreviated).day().year()))")
                                .font(.outfit(size: 11))
                                .foregroundStyle(Color.charcoalPale)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 0) {
                        Text("\(user.recipesCount)")
                            .font(.outfit(size: 16, weight: .bold))
                            .foregroundStyle(Color.charcoal)
                        Text(user.recipesCount == 1 ? "recipe" : "recipes")
                            .font(.outfit(size: 10))
                            .foregroundStyle(Color.charcoalLight)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.charcoalPale)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().overlay(Color.creamBorder)
        }
    }

    private func avatar(_ user: User) -> some View {
        let color = Color(hex: user.avatarColorHex)
        return Text(user.username.first.map { String($0).uppercased() } ?? "?")
            .font(.lora(size: 16, weight: .bold))
            .foregroundStyle(color)
            .frame(width: 40, height: 40)
            .background(color.opacity(0.15), in: Circle())
    }

    private var youTag: some View {
        Text("YOU")
            .font(.outfit(size: 10, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(Color.charcoalMid)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.charcoal.opacity(0.08), in: Capsule())
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoalLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await controller.load() }
            } label: {
                Text("Retry")
                    .font(.outfit(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.terracotta, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 64)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    NavigationStack {
        AdminUsersScreen()
    }
    .environment(AppRouter())
}
