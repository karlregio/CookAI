//
//  CookProfileScreen.swift
//  CookAI
//
//  Ports "User Profile (Public View)" from the Figma prototype: banner with a
//  back button, overlapping avatar, name, bio, stats, a Message button and
//  the cook's published recipes.
//

import SwiftUI

struct CookProfileScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var controller: CookProfileController

    private let gridColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    init(user: User) {
        _controller = State(initialValue: CookProfileController(user: user))
    }

    private var tint: Color { Color(hex: controller.user.avatarColorHex) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                banner
                identity
                recipesSection
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { Task { await controller.load() } }
    }

    // MARK: - Banner

    private var banner: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(hex: "#EDE0D3"), Color(hex: "#F5EDE4")], startPoint: .top, endPoint: .bottom)
            CustomBackButton { dismiss() }
                .padding(.leading, 16)
                .padding(.top, 56)
        }
        .frame(height: 180)
    }

    // MARK: - Identity

    private var identity: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom) {
                avatar
                Spacer()
                if !controller.isMe && controller.isSignedIn {
                    messageButton.padding(.bottom, 4)
                }
            }
            .padding(.top, -48)

            HStack(spacing: 6) {
                Text(controller.user.displayName)
                    .font(.lora(size: 20, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                if controller.user.isVerified {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(tint)
                }
            }
            .padding(.top, 12)

            Text("@\(controller.user.username)")
                .font(.outfit(size: 13))
                .foregroundStyle(Color.charcoalLight)
                .padding(.top, 2)

            if !controller.user.bio.isEmpty {
                Text(controller.user.bio)
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoalMid)
                    .padding(.top, 8)
            }

            if let message = controller.errorMessage {
                Text(message)
                    .font(.outfit(size: 12))
                    .foregroundStyle(Color(hex: "#9C2B2B"))
                    .padding(.top, 8)
            }

            HStack(spacing: 24) {
                stat("Recipes", controller.hasLoaded ? controller.recipes.count : controller.user.recipesCount)
                stat("Total Likes", controller.hasLoaded ? controller.totalLikes : controller.user.totalLikes)
            }
            .padding(.top, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) { Divider().overlay(Color.creamBorder) }
        }
        .padding(.horizontal, 20)
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(tint)
            if controller.user.isVerified {
                Image(systemName: "sparkle").font(.system(size: 34, weight: .bold)).foregroundStyle(.white)
            } else {
                Text(String(controller.user.displayName.prefix(1)).uppercased())
                    .font(.lora(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 96, height: 96)
        .overlay(Circle().stroke(Color.cream, lineWidth: 4))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }

    private var messageButton: some View {
        Button {
            Task {
                if let conversation = await controller.openConversation() {
                    router.push(.chat(conversation, controller.user))
                }
            }
        } label: {
            HStack(spacing: 6) {
                if controller.isOpeningChat {
                    ProgressView().tint(Color.terracotta).controlSize(.small)
                } else {
                    Image(systemName: "bubble.left").font(.system(size: 14, weight: .semibold))
                }
                Text("Message").font(.outfit(size: 14, weight: .semibold))
            }
            .foregroundStyle(Color.terracotta)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .overlay(Capsule().stroke(Color.terracotta, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(controller.isOpeningChat)
    }

    private func stat(_ label: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.outfit(size: 20, weight: .bold))
                .foregroundStyle(Color.charcoal)
            Text(label)
                .font(.outfit(size: 12))
                .foregroundStyle(Color.charcoalLight)
        }
    }

    // MARK: - Recipes

    private var recipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Published Recipes")
                .font(.lora(size: 16, weight: .semibold))
                .foregroundStyle(Color.charcoal)

            if !controller.hasLoaded {
                ProgressView().tint(Color.terracotta).frame(maxWidth: .infinity).padding(.top, 24)
            } else if controller.recipes.isEmpty {
                VStack(spacing: 8) {
                    Text("🍽").font(.system(size: 32))
                    Text("No recipes yet")
                        .font(.outfit(size: 14))
                        .foregroundStyle(Color.charcoalLight)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(controller.recipes) { recipe in
                        RecipeCard(recipe: recipe, uploader: controller.user) {
                            router.push(.recipeOverview(recipe))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 40)
    }
}

#Preview {
    NavigationStack { CookProfileScreen(user: MockData.naomiCooks) }
        .environment(AppRouter())
}
