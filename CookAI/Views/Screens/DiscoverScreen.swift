//
//  DiscoverScreen.swift
//  CookAI
//
//  Discover tab root: recipes shared by other cooks. Search by dish, cuisine
//  or @username, filter by cuisine, and tap any card to open its overview
//  (where you can rate, comment, save and cook it). The "Share a recipe"
//  button opens UploadRecipeScreen.
//

import SwiftUI

struct DiscoverScreen: View {
    private let gridColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    @Environment(AppRouter.self) private var router
    @State private var controller = DiscoverController()

    var body: some View {
        VStack(spacing: 0) {
            header
            searchAndChips
            content
        }
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        // Also fires when returning from Upload, so a new recipe shows up right away.
        .onAppear { Task { await controller.load() } }
        .onChange(of: router.selectedTab) { _, newTab in
            if newTab == .discover {
                Task { await controller.load() }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Discover")
                    .font(.lora(size: 24, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                Text("Recipes from cooks around the world")
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoalLight)
            }
            Spacer()
            Button {
                router.push(.uploadRecipe)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Share")
                        .font(.outfit(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.terracotta, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var searchAndChips: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                ForEach(DiscoverController.Mode.allCases) { mode in
                    CategoryChip(title: mode.rawValue, isActive: controller.mode == mode) {
                        controller.mode = mode
                    }
                }
            }
            .padding(.horizontal, 20)

            SearchBar(
                text: $controller.searchText,
                placeholder: controller.mode == .recipes ? "Search dishes, cuisines, cooks..." : "Search cooks by name or @username..."
            )
            .padding(.horizontal, 20)

            if controller.mode == .recipes {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(controller.cuisines, id: \.self) { cuisine in
                            CategoryChip(title: cuisine, isActive: controller.selectedCuisine == cuisine) {
                                controller.selectedCuisine = cuisine
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Content

    private var content: some View {
        Group {
            if controller.mode == .cooks {
                cooksList
            } else if controller.isLoading && controller.recipes.isEmpty {
                ProgressView()
                    .tint(Color.terracotta)
                    .padding(.top, 64)
            } else if let message = controller.errorMessage, controller.recipes.isEmpty {
                errorState(message)
            } else if controller.filteredRecipes.isEmpty {
                emptyState
            } else {
                recipeGrid
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Cooks

    @ViewBuilder
    private var cooksList: some View {
        if controller.shownCooks.isEmpty {
            VStack(spacing: 8) {
                Text("👩‍🍳").font(.system(size: 36))
                Text(controller.isLoading ? "Loading cooks..." : "No cooks match your search")
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoalLight)
            }
            .padding(.top, 64)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(controller.shownCooks) { cook in
                        cookRow(cook)
                        Divider().overlay(Color.creamBorder)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .refreshable { await controller.load() }
        }
    }

    private func cookRow(_ cook: User) -> some View {
        Button {
            router.push(.cookProfile(cook))
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color(hex: cook.avatarColorHex))
                    Text(String(cook.displayName.prefix(1)).uppercased())
                        .font(.lora(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(cook.displayName)
                            .font(.outfit(size: 14, weight: .semibold))
                            .foregroundStyle(Color.charcoal)
                        if cook.isVerified {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: cook.avatarColorHex))
                        }
                    }
                    Text("@\(cook.username) · \(cook.recipesCount) recipe\(cook.recipesCount == 1 ? "" : "s")")
                        .font(.outfit(size: 12))
                        .foregroundStyle(Color.charcoalLight)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.charcoalPale)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var recipeGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(controller.filteredRecipes) { recipe in
                    RecipeCard(recipe: recipe, uploader: controller.uploader(for: recipe)) {
                        router.push(.recipeOverview(recipe))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .refreshable { await controller.load() }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🌍").font(.system(size: 36))
            Text(controller.recipes.isEmpty ? "No shared recipes yet" : "No recipes match your search")
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoalLight)
        }
        .padding(.top, 64)
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
    }
}

#Preview {
    NavigationStack {
        DiscoverScreen()
    }
    .environment(AppRouter())
}
