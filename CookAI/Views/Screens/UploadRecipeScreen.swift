//
//  UploadRecipeScreen.swift
//  CookAI
//
//  Share a recipe with the community: photo, name, free-text cuisine, time,
//  servings, difficulty, ingredients and steps. Signed-in users only.
//

import PhotosUI
import SwiftUI

struct UploadRecipeScreen: View {
    @Environment(AppRouter.self) private var router
    @Environment(AuthController.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var controller: UploadRecipeController
    @State private var pickerItem: PhotosPickerItem?
    private let isEditing: Bool

    /// Pass a recipe to edit it; leave nil to share a new one.
    init(editing recipe: Recipe? = nil) {
        _controller = State(initialValue: UploadRecipeController(editing: recipe))
        isEditing = recipe != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if auth.currentUser == nil {
                guestState
            } else {
                form
            }
        }
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: controller.publishedRecipe) { _, recipe in
            guard let recipe else { return }
            // Replace this form with the new recipe so Back returns to Discover.
            router.pop()
            // When editing, the old copy of the recipe sits underneath: replace it too.
            if isEditing { router.pop() }
            router.push(.recipeOverview(recipe))
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            CustomBackButton { dismiss() }
            Text(isEditing ? "Edit recipe" : "Share a recipe")
                .font(.lora(size: 22, weight: .semibold))
                .foregroundStyle(Color.charcoal)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var guestState: some View {
        VStack(spacing: 12) {
            Text("👩‍🍳").font(.system(size: 40))
            Text("Log in to share a recipe")
                .font(.lora(size: 18, weight: .semibold))
                .foregroundStyle(Color.charcoal)
            Text("Guests can browse and cook, but sharing needs an account.")
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoalLight)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                photoSection
                labeled("Recipe name") {
                    TextField("What do you call it?", text: $controller.title)
                }
                cuisineSection
                HStack(spacing: 12) {
                    labeled("Cook time (min)") {
                        TextField("Minutes", text: $controller.cookTimeText).keyboardType(.numberPad)
                    }
                    labeled("Servings") {
                        TextField("People", text: $controller.servingsText).keyboardType(.numberPad)
                    }
                }
                difficultySection
                ingredientsSection
                stepsSection
                if let message = controller.errorMessage {
                    Text(message)
                        .font(.outfit(size: 13, weight: .medium))
                        .foregroundStyle(Color.terracottaDark)
                }
                publishButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Photo

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Photo")
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack {
                    if let data = controller.photoData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else if let url = controller.existingImageURL {
                        AsyncImage(url: url) { phase in
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill()
                            } else {
                                Color.cream
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: controller.isPreparingPhoto ? "hourglass" : "photo.badge.plus")
                                .font(.system(size: 28, weight: .light))
                            Text("Add a photo")
                                .font(.outfit(size: 14, weight: .medium))
                        }
                        .foregroundStyle(Color.charcoalLight)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    let data = try? await item.loadTransferable(type: Data.self)
                    controller.setPhoto(data)
                    pickerItem = nil
                }
            }

            if isEditing && controller.photoData == nil {
                Text("Tap the photo to replace it.")
                    .font(.outfit(size: 12))
                    .foregroundStyle(Color.charcoalLight)
            }
            if controller.photoData != nil {
                Button(isEditing ? "Keep the current photo" : "Remove photo") { controller.removePhoto() }
                    .font(.outfit(size: 12, weight: .medium))
                    .foregroundStyle(Color.terracottaDark)
            }
        }
    }

    // MARK: Cuisine / difficulty

    private var cuisineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            labeled("Cuisine") {
                TextField("Type any cuisine", text: $controller.cuisine)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(controller.suggestedCuisines, id: \.self) { name in
                        CategoryChip(title: name, isActive: controller.cuisine == name) {
                            controller.cuisine = name
                        }
                    }
                }
            }
        }
    }

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Difficulty")
            HStack(spacing: 8) {
                ForEach([Difficulty.easy, .medium, .hard], id: \.self) { level in
                    CategoryChip(title: level.rawValue, isActive: controller.difficulty == level) {
                        controller.difficulty = level
                    }
                }
            }
        }
    }

    // MARK: Ingredients / steps

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Ingredients")
            ForEach($controller.ingredientRows) { $row in
                HStack(spacing: 8) {
                    field { TextField("Ingredient", text: $row.name) }
                    field { TextField("Amount", text: $row.quantity) }.frame(width: 110)
                    removeButton { controller.removeIngredientRow(row.id) }
                }
            }
            addButton("Add ingredient") { controller.addIngredientRow() }
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Steps")
            ForEach($controller.stepRows) { $row in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(controller.stepNumber(for: row.id))")
                        .font(.outfit(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.terracotta, in: Circle())
                        .padding(.top, 12)
                    VStack(spacing: 6) {
                        field { TextField("Describe this step", text: $row.text, axis: .vertical) }
                        field { TextField("Timer in minutes (optional)", text: $row.timerMinutes).keyboardType(.numberPad) }
                    }
                    removeButton { controller.removeStepRow(row.id) }
                        .padding(.top, 12)
                }
            }
            addButton("Add step") { controller.addStepRow() }
        }
    }

    private var publishButton: some View {
        Button {
            Task { await controller.submit() }
        } label: {
            HStack(spacing: 8) {
                if controller.isSubmitting {
                    ProgressView().tint(.white)
                }
                Text(controller.isSubmitting ? (isEditing ? "Saving..." : "Publishing...") : (isEditing ? "Save changes" : "Publish recipe"))
                    .font(.outfit(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.terracotta, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(controller.isSubmitting || controller.isPreparingPhoto)
        .opacity(controller.isSubmitting ? 0.7 : 1)
    }

    // MARK: Small pieces

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.outfit(size: 11, weight: .semibold))
            .foregroundStyle(Color.charcoalMid)
    }

    private func labeled<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel(label)
            field(content: content)
        }
    }

    private func field<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .font(.outfit(size: 14))
            .foregroundStyle(Color.charcoal)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func removeButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "minus.circle")
                .font(.system(size: 18))
                .foregroundStyle(Color.charcoalPale)
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }

    private func addButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: "plus")
                .font(.outfit(size: 13, weight: .semibold))
                .foregroundStyle(Color.terracotta)
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }
}

#Preview {
    NavigationStack {
        UploadRecipeScreen()
    }
    .environment(AppRouter())
    .environment(AuthController())
}
