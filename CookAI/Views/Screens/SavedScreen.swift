//
//  SavedScreen.swift
//  CookAI
//
//  Ports SavedScreen from App.tsx (~lines 2968–3076): a grid/list view
//  toggle over the saved recipes, using the existing RecipeCard component.
//  Unlike the prototype (which hardcodes `RECIPES.slice(0, 4)`), this reads
//  genuinely shared save state via SavedController, and adds a small
//  bookmark overlay so recipes can be unsaved right from this screen.
//

import SwiftUI

struct SavedScreen: View {
    private enum ViewMode {
        case grid
        case list
    }

    @Environment(AppRouter.self) private var router
    @State private var controller = SavedController()
    @State private var viewMode: ViewMode = .grid

    private let gridColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await controller.load() }
        .onChange(of: router.selectedTab) { _, newTab in
            if newTab == .saved {
                Task { await controller.load() }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Saved Recipes")
                    .font(.lora(size: 24, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                Spacer()
                viewModeToggle
            }

            if !controller.recipes.isEmpty {
                Text("\(controller.recipes.count) recipe\(controller.recipes.count == 1 ? "" : "s") saved")
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoalLight)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var viewModeToggle: some View {
        HStack(spacing: 2) {
            toggleButton(mode: .grid, systemImage: "square.grid.2x2")
            toggleButton(mode: .list, systemImage: "list.bullet")
        }
        .padding(3)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))
    }

    private func toggleButton(mode: ViewMode, systemImage: String) -> some View {
        Button {
            viewMode = mode
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(viewMode == mode ? .white : Color.charcoalLight)
                .frame(width: 32, height: 28)
                .background(viewMode == mode ? Color.terracotta : Color.clear, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    private var content: some View {
        Group {
            if controller.isLoading && controller.recipes.isEmpty {
                loadingState
            } else if let error = controller.errorMessage, controller.recipes.isEmpty {
                errorState(error)
            } else if controller.recipes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("RECENTLY SAVED")
                            .font(.outfit(size: 11, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(Color.charcoalMid)

                        if viewMode == .grid {
                            gridContent
                        } else {
                            listContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .refreshable { await controller.load() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var gridContent: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(controller.recipes) { recipe in
                ZStack(alignment: .topTrailing) {
                    RecipeCard(recipe: recipe, uploader: controller.uploader(for: recipe)) {
                        router.push(.recipeOverview(recipe))
                    }
                    unsaveButton(recipe)
                        .padding(8)
                }
            }
        }
    }

    private var listContent: some View {
        VStack(spacing: 12) {
            ForEach(controller.recipes) { recipe in
                ZStack(alignment: .topTrailing) {
                    Button {
                        router.push(.recipeOverview(recipe))
                    } label: {
                        listRow(recipe)
                    }
                    .buttonStyle(.plain)

                    unsaveButton(recipe)
                        .padding(10)
                }
            }
        }
    }

    private func listRow(_ recipe: Recipe) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Color(hex: "#E8DDD5")
                AsyncImage(url: recipe.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "fork.knife").foregroundStyle(Color.charcoalLight)
                    default:
                        Color.cream
                    }
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.lora(size: 14, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                Text("\(recipe.cuisine) · \(recipe.formattedTime)")
                    .font(.outfit(size: 12))
                    .foregroundStyle(Color.charcoalLight)
                DifficultyBadge(difficulty: recipe.difficulty)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .softShadow()
    }

    private func unsaveButton(_ recipe: Recipe) -> some View {
        Button {
            Task { await controller.unsave(recipe) }
        } label: {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Color.terracotta, in: Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🔖").font(.system(size: 36))
            Text("No saved recipes yet")
                .font(.outfit(size: 15, weight: .semibold))
                .foregroundStyle(Color.charcoal)
            Text("Tap the bookmark icon on any recipe to save it here.")
                .font(.outfit(size: 13))
                .foregroundStyle(Color.charcoalLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var loadingState: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.charcoal.opacity(0.06))
                        .frame(height: 180)
                        .redacted(reason: .placeholder)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
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
        .frame(maxWidth: .infinity)
        .padding(.top, 64)
    }
}

#Preview {
    NavigationStack {
        SavedScreen()
    }
    .environment(AppRouter())
}
