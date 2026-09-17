//
//  ProfileScreen.swift
//  CookAI
//
//  Ports ProfileScreen from App.tsx (~lines 3190–3398). Per PROJECT_RULES.md,
//  identity (avatar initial, name, email) always comes from AuthController —
//  never the prototype's hardcoded "Alex Rivera" / "A" / "24 recipes cooked".
//  The prototype's Dietary Preferences and Measurement Units sections are
//  intentionally skipped: there's no Service/model backing that state, and
//  faking a persisted preference would violate PROJECT_RULES.md #3.
//

import SwiftUI

struct ProfileScreen: View {
    @Environment(AppRouter.self) private var router
    @Environment(AuthController.self) private var auth
    @State private var controller = ProfileController()
    @State private var showAboutSheet = false

    private let cuisineColumns = [GridItem(.adaptive(minimum: 84), spacing: 8, alignment: .leading)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                favoriteCuisinesSection
                settingsSection
                logOutButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await controller.load() }
        .onChange(of: router.selectedTab) { _, newTab in
            if newTab == .profile {
                Task { await controller.load() }
            }
        }
        .sheet(isPresented: $showAboutSheet) {
            aboutSheet
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Profile")
                .font(.lora(size: 24, weight: .semibold))
                .foregroundStyle(Color.charcoal)

            HStack(spacing: 16) {
                avatar

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.lora(size: 18, weight: .semibold))
                        .foregroundStyle(Color.charcoal)
                    Text(subtitleText)
                        .font(.outfit(size: 13))
                        .foregroundStyle(Color.charcoalLight)
                }
            }
        }
    }

    private var displayName: String {
        auth.currentUser?.displayName ?? "Guest"
    }

    private var subtitleText: String {
        guard let user = auth.currentUser else {
            return "Browsing as a guest"
        }
        return "\(user.email)\n\(statsLine)"
    }

    private var statsLine: String {
        guard let user = auth.currentUser else { return "" }
        let uploaded = "\(user.recipesCount) recipe\(user.recipesCount == 1 ? "" : "s") uploaded"
        let likes = "\(user.totalLikes) like\(user.totalLikes == 1 ? "" : "s")"
        let cooked = "\(controller.cookedCount) cooked"
        return [uploaded, likes, cooked].joined(separator: " · ")
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color.terracotta, Color.terracottaDark], startPoint: .topLeading, endPoint: .bottomTrailing))

            if let name = auth.currentUser?.displayName, let first = name.first {
                Text(String(first).uppercased())
                    .font(.lora(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 64, height: 64)
        .softShadow()
    }

    // MARK: - Favorite cuisines

    private var favoriteCuisinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FAVORITE CUISINES")
                .font(.outfit(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color.charcoalMid)

            LazyVGrid(columns: cuisineColumns, alignment: .leading, spacing: 8) {
                ForEach(controller.allCuisines, id: \.self) { cuisine in
                    CategoryChip(title: cuisine, isActive: controller.selectedCuisines.contains(cuisine)) {
                        controller.toggleCuisine(cuisine)
                    }
                }
            }
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APP SETTINGS")
                .font(.outfit(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color.charcoalMid)

            VStack(spacing: 0) {
                settingsRow(icon: "🔔", title: "Notifications") {
                    router.push(.notifications)
                }
                Divider().overlay(Color.creamBorder)
                settingsRow(icon: "⭐", title: "Rate the app") {
                    router.push(.comingSoon(title: "Rate the App"))
                }
                Divider().overlay(Color.creamBorder)
                settingsRow(icon: "ℹ️", title: "About CookAI") {
                    showAboutSheet = true
                }

                if auth.currentUser?.role == .admin {
                    Divider().overlay(Color.creamBorder)
                    adminRow
                }
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .softShadow()
        }
    }

    private func settingsRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(icon).font(.system(size: 17))
                Text(title)
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoal)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.charcoalPale)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var adminRow: some View {
        Button {
            router.push(.comingSoon(title: "Admin Dashboard"))
        } label: {
            HStack(spacing: 12) {
                Text("🛡️").font(.system(size: 17))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Admin Dashboard")
                        .font(.outfit(size: 14))
                        .foregroundStyle(Color.charcoal)
                    Text("ADMIN ONLY")
                        .font(.outfit(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(Color.terracotta)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.charcoalPale)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Log out

    private var logOutButton: some View {
        Button {
            Task { await auth.signOut() }
        } label: {
            Text("Log Out")
                .font(.outfit(size: 15, weight: .semibold))
                .foregroundStyle(Color.terracotta)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.terracotta.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - About sheet

    private var aboutSheet: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(Color.charcoal.opacity(0.15))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            CookAILogoMark(containerSize: 64, iconSize: 34, cornerRadius: 18)
                .padding(.top, 16)

            Text("CookAI")
                .font(.lora(size: 22, weight: .semibold))
                .foregroundStyle(Color.charcoal)

            Text("Your AI-powered kitchen companion")
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoalLight)

            Text(appVersion)
                .font(.outfit(size: 12))
                .foregroundStyle(Color.charcoalPale)
                .padding(.top, 6)

            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.hidden)
        .background(Color.cream)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}

#Preview {
    NavigationStack {
        ProfileScreen()
    }
    .environment(AppRouter())
    .environment(AuthController())
}
