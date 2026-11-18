//
//  DiscoverScreen.swift
//  CookAI
//
//  Discover tab root: recipes shared by other cooks. Search by dish, cuisine
//  or @username, filter by cuisine, and tap any card to open its overview
//  (where you can rate, comment, save and cook it). The "Share a recipe"
//  button is the entry point for Upload, which is built next.
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
        .task { await controller.load() }
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
                router.push(.comingSoon(title: "Share a Recipe"))
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
            SearchBar(text: $controller.searchText, placeholder: "Search dishes, cuisines, cooks...")
                .padding(.horizontal, 20)

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
        .padding(.bottom, 16)
    }

    // MARK: - Content

    private var content: some View {
        Group {
            if controller.isLoading && controller.recipes.isEmpty {
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
