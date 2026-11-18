//
//  RecipeOverviewScreen.swift
//  CookAI
//
//  Ports RecipeOverviewScreen from App.tsx (~lines 1592–2372), section by
//  section: hero photo with glass action buttons and a fullscreen zoomable
//  viewer, title/meta glass card, rating + like, ingredients with swap,
//  add-to-grocery, AI nutrition estimate, AI pairing suggestions, an
//  instructions accordion, regenerate-with-AI (AI recipes only) or
//  save/share (everything else), a sticky Start Cooking button, and
//  comments. All state lives in RecipeOverviewController; all data comes
//  through RecipeRepository/AIService — never MockData directly.
//

import SwiftUI

struct RecipeOverviewScreen: View {
    @Environment(AppRouter.self) private var router
    @Environment(AuthController.self) private var auth
    @Environment(GroceryController.self) private var grocery

    @State private var controller: RecipeOverviewController
    @State private var showFullscreenImage = false
    @State private var isRateSheetPresented = false
    @State private var showInstructions = false
    @State private var showDeleteConfirm = false
    @State private var commentToDelete: RecipeComment?

    init(recipe: Recipe) {
        _controller = State(initialValue: RecipeOverviewController(recipe: recipe))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroImage
                    glassInfoCard
                        .padding(.horizontal, 16)
                        .offset(y: -56)

                    content
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
            }
            .ignoresSafeArea(edges: .top)

            // Stays on screen while the page scrolls, so Back is always reachable.
            VStack {
                topBar
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)

            if let toastMessage = controller.toastMessage {
                toast(toastMessage)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if showFullscreenImage {
                FullscreenImageViewer(imageURL: controller.recipe.imageURL, accessibilityLabel: controller.recipe.title) {
                    showFullscreenImage = false
                }
                .transition(.opacity)
                .zIndex(2)
            }

            if let ingredientId = controller.swapSheetIngredientId {
                SwapIngredientSheet(
                    ingredientName: ingredientName(for: ingredientId),
                    inputText: $controller.swapInputText,
                    isLoading: controller.isRequestingSubstitution,
                    suggestion: controller.swapSuggestion,
                    errorMessage: controller.swapErrorMessage,
                    onAsk: { Task { await controller.requestSubstitution() } },
                    onConfirm: { controller.confirmSwap() },
                    onClose: { controller.cancelSwap() }
                )
                .transition(.move(edge: .bottom))
                .zIndex(3)
            }

            if isRateSheetPresented {
                RateRecipeSheet(
                    currentAverage: controller.recipe.ratingAverage,
                    currentCount: controller.recipe.ratingCount,
                    selectedRating: $controller.myRating,
                    isSubmitting: controller.isSubmittingRating,
                    onSubmit: {
                        Task {
                            await controller.submitRating()
                            isRateSheetPresented = false
                        }
                    },
                    onCancel: { isRateSheetPresented = false }
                )
                .transition(.move(edge: .bottom))
                .zIndex(3)
            }
        }
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: controller.toastMessage)
        .task { await controller.loadSecondaryContent() }
        .confirmationDialog(
            "Delete \"\(controller.recipe.title)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete recipe", role: .destructive) {
                Task {
                    if await controller.deleteRecipe() { router.pop() }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the recipe, its comments and its photo.")
        }
    }

    private func ingredientName(for id: UUID) -> String {
        controller.recipe.ingredients.first(where: { $0.id == id })?.name ?? ""
    }

    // MARK: - Hero

    private var heroImage: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: "#E8DDD5")

            AsyncImage(url: controller.recipe.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Image(systemName: "fork.knife")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(Color.charcoalLight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                default:
                    Color.cream
                }
            }
            .frame(maxWidth: .infinity)
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture { showFullscreenImage = true }

            LinearGradient(colors: [.black.opacity(0.4), .clear], startPoint: .bottom, endPoint: .top)
                .allowsHitTesting(false)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.black.opacity(0.3), in: Circle())
                        .padding(.trailing, 16)
                        .padding(.bottom, 64)
                }
            }
            .allowsHitTesting(false)

        }
        .frame(height: 338)
    }

    private var topBar: some View {
        HStack {
            CustomBackButton { router.pop() }
            Spacer()
            HStack(spacing: 8) {
                if isOwner { ownerMenu }
                saveButton
                shareButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var isOwner: Bool {
        guard let me = auth.currentUser?.id else { return false }
        return me == controller.recipe.uploaderId
    }

    private var ownerMenu: some View {
        Menu {
            Button {
                router.push(.editRecipe(controller.recipe))
            } label: {
                Label("Edit recipe", systemImage: "pencil")
            }
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete recipe", systemImage: "trash")
            }
        } label: {
            Image(systemName: controller.isDeleting ? "hourglass" : "ellipsis")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.charcoal)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.8), in: Circle())
        }
        .disabled(controller.isDeleting)
    }

    private var saveButton: some View {
        Button {
            Task { await controller.toggleSave() }
        } label: {
            Image(systemName: controller.isSaved ? "bookmark.fill" : "bookmark")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(controller.isSaved ? .white : Color.charcoal)
                .frame(width: 40, height: 40)
                .background(controller.isSaved ? Color.terracotta : Color.white.opacity(0.8), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(controller.isTogglingSave)
    }

    private var shareButton: some View {
        ShareLink(item: controller.recipe.title) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.charcoal)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.8), in: Circle())
        }
    }

    // MARK: - Glass info card

    private var glassInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(controller.recipe.title)
                    .font(.lora(size: 18, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                    .lineLimit(2)

                Spacer()

                HStack(spacing: 8) {
                    likeButton
                    Text(controller.recipe.cuisine)
                        .font(.outfit(size: 11, weight: .semibold))
                        .foregroundStyle(Color.terracotta)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.terracotta.opacity(0.15), in: Capsule())
                }
            }

            HStack(spacing: 0) {
                heroStat(icon: "⏱", label: controller.recipe.formattedTime)
                heroStat(icon: "👥", label: "\(controller.recipe.servings) servings")
                heroStat(icon: "📊", label: controller.recipe.difficulty.rawValue)
            }
        }
        .padding(16)
        .glassCard()
        .softShadow()
    }

    private func heroStat(icon: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(icon).font(.system(size: 16))
            Text(label)
                .font(.outfit(size: 11, weight: .medium))
                .foregroundStyle(Color.charcoalMid)
        }
        .frame(maxWidth: .infinity)
    }

    private var likeButton: some View {
        Button {
            Task { await controller.toggleLike() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: controller.isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 12))
                Text("\(controller.likeCount)")
                    .font(.outfit(size: 12, weight: .semibold))
            }
            .foregroundStyle(controller.isLiked ? Color.terracotta : Color.charcoalMid)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(controller.isLiked ? Color.terracotta.opacity(0.12) : Color.charcoal.opacity(0.06), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(controller.isTogglingLike)
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let uploader = controller.uploader {
                Button {
                    router.push(.cookProfile(uploader))
                } label: {
                    HStack {
                        UploaderAttributionView(user: uploader, size: .md)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.charcoalPale)
                    }
                }
                .buttonStyle(.plain)
            }

            ratingRow

            ingredientsSection

            nutritionCard

            instructionsAccordion

            pairingCard

            regenerateOrSaveShareRow

            startCookingButton

            commentsSection
        }
    }

    // MARK: - Rating row

    private var ratingRow: some View {
        Group {
            if controller.recipe.ratingCount > 0 {
                Button {
                    controller.myRating = 0
                    isRateSheetPresented = true
                } label: {
                    HStack {
                        StarRatingView(average: controller.recipe.ratingAverage, count: controller.recipe.ratingCount, size: 16)
                        Spacer()
                        Text("Rate this recipe →")
                            .font(.outfit(size: 12, weight: .semibold))
                            .foregroundStyle(Color.starGold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.starGold.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.starGold.opacity(0.18), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ingredients")
                    .font(.lora(size: 18, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                Spacer()
                addToGroceryButton
            }

            VStack(spacing: 4) {
                ForEach(controller.ingredientRows) { row in
                    ingredientRow(row)
                }
            }

            if !controller.substitutions.isEmpty {
                activeSwapsSummary
            }
        }
    }

    private var addToGroceryButton: some View {
        Button {
            let wanted = controller.groceryEntriesToAdd
            let added = grocery.addItems(wanted, recipeTitle: controller.recipe.title)
            controller.clearIngredientSelection()
            if added == 0 {
                controller.showToast("Already on your Grocery List")
            } else {
                controller.showToast("Added \(added) item\(added == 1 ? "" : "s") under \(controller.recipe.title)")
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "bag")
                    .font(.system(size: 12, weight: .semibold))
                Text(controller.selectedIngredientCount > 0 ? "Add \(controller.selectedIngredientCount) selected" : "Add all to List")
                    .font(.outfit(size: 12, weight: .semibold))
            }
            .foregroundStyle(Color.sage)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.sage.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(Color.sage.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func ingredientRow(_ row: RecipeIngredientRow) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    controller.toggleChecked(row.id)
                } label: {
                    checkbox(isChecked: controller.checkedIngredientIds.contains(row.id))
                }
                .buttonStyle(.plain)

                Button {
                    controller.toggleExpanded(row.id)
                } label: {
                    HStack(spacing: 8) {
                        Text(row.displayText)
                            .font(.outfit(size: 14))
                            .foregroundStyle(controller.checkedIngredientIds.contains(row.id) ? Color.charcoalLight : Color.charcoal)
                            .strikethrough(controller.checkedIngredientIds.contains(row.id))

                        if row.isSwapped {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 8, weight: .bold))
                                Text("swapped")
                                    .font(.outfit(size: 10, weight: .semibold))
                            }
                            .foregroundStyle(Color.sage)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.sage.opacity(0.15), in: Capsule())
                        }

                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    controller.toggleExpanded(row.id)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.charcoalMid)
                        .rotationEffect(.degrees(controller.expandedIngredientId == row.id ? 180 : 0))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)

            if controller.expandedIngredientId == row.id {
                swapActionRow(row)
            }
        }
    }

    private func checkbox(isChecked: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isChecked ? Color.sage : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isChecked ? Color.sage : Color.charcoal.opacity(0.2), lineWidth: 1)
                )
            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 20, height: 20)
    }

    private func swapActionRow(_ row: RecipeIngredientRow) -> some View {
        HStack(spacing: 8) {
            if row.isSwapped {
                Text(usingLabel(row.displayText))
                Spacer()
                Button("Undo") {
                    controller.undoSwap(for: row.id)
                }
                .font(.outfit(size: 11, weight: .medium))
                .foregroundStyle(Color.charcoalLight)
                .underline()
                .buttonStyle(.plain)
            } else {
                Text("Don't have this?")
                    .font(.outfit(size: 12))
                    .foregroundStyle(Color.charcoalMid)
                Spacer()
                Button {
                    controller.beginSwap(for: row.id)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 9, weight: .bold))
                        Text("Swap ingredient")
                            .font(.outfit(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.terracotta, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: "#FDF3EC"), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.terracotta.opacity(0.15), lineWidth: 1))
        .padding(.leading, 32)
        .padding(.bottom, 4)
    }

    private func usingLabel(_ replacement: String) -> AttributedString {
        var prefix = AttributedString("Using ")
        prefix.font = .outfit(size: 12)
        prefix.foregroundColor = Color.charcoalMid

        var name = AttributedString(replacement)
        name.font = .outfit(size: 12, weight: .semibold)
        name.foregroundColor = Color.charcoal

        prefix.append(name)
        return prefix
    }

    private var activeSwapsSummary: some View {
        let count = controller.substitutions.count
        return VStack(alignment: .leading, spacing: 4) {
            Text("\(count) INGREDIENT\(count > 1 ? "S" : "") SWAPPED")
                .font(.outfit(size: 11, weight: .semibold))
                .tracking(0.7)
                .foregroundStyle(Color.sage)
            Text("Recipe adapted · AI notes saved for Cook Mode")
                .font(.outfit(size: 12))
                .foregroundStyle(Color.charcoalMid)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.sage.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.sage.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Nutrition

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.sage)
                Text("AI ESTIMATED · PER SERVING")
                    .font(.outfit(size: 11, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(Color.sage)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            if controller.isLoadingNutrition {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Estimating nutrition...")
                        .font(.outfit(size: 12))
                        .foregroundStyle(Color.charcoalLight)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            } else if let error = controller.nutritionErrorMessage {
                Text(error)
                    .font(.outfit(size: 12))
                    .foregroundStyle(Color.terracottaDark)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            } else if let nutrition = controller.nutrition {
                HStack(spacing: 0) {
                    nutritionStat(value: "\(nutrition.caloriesPerServing)", unit: "kcal", label: "Calories", showDivider: true)
                    nutritionStat(value: "\(nutrition.proteinGrams)", unit: "g", label: "Protein", showDivider: true)
                    nutritionStat(value: "\(nutrition.carbsGrams)", unit: "g", label: "Carbs", showDivider: true)
                    nutritionStat(value: "\(nutrition.fatGrams)", unit: "g", label: "Fat", showDivider: false)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)

                Text(nutrition.notes)
                    .font(.outfit(size: 10))
                    .foregroundStyle(Color.charcoalPale)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .background(Color.creamCard)
        .overlay(alignment: .leading) {
            Rectangle().fill(Color.sage).frame(width: 3)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.sage.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .softShadow()
    }

    private func nutritionStat(value: String, unit: String, label: String, showDivider: Bool) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.outfit(size: 20, weight: .bold))
                .foregroundStyle(Color.charcoal)
            Text(unit)
                .font(.outfit(size: 10, weight: .medium))
                .foregroundStyle(Color.charcoalLight)
            Text(label)
                .font(.outfit(size: 10))
                .foregroundStyle(Color.charcoalPale)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            if showDivider {
                Rectangle().fill(Color.sage.opacity(0.15)).frame(width: 1)
            }
        }
    }

    // MARK: - Instructions accordion

    private var instructionsAccordion: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showInstructions.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Instructions Preview")
                            .font(.lora(size: 16, weight: .semibold))
                            .foregroundStyle(Color.charcoal)
                        Text("\(controller.recipe.steps.count) steps total")
                            .font(.outfit(size: 12))
                            .foregroundStyle(Color.charcoalLight)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Color.charcoalLight)
                        .rotationEffect(.degrees(showInstructions ? 180 : 0))
                }
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .overlay(alignment: .top) { Rectangle().fill(Color.creamBorder).frame(height: 1) }
            .overlay(alignment: .bottom) { Rectangle().fill(Color.creamBorder).frame(height: 1) }

            if showInstructions {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(controller.recipe.steps.sorted(by: { $0.order < $1.order })) { step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(step.order)")
                                .font(.outfit(size: 11, weight: .bold))
                                .foregroundStyle(Color.terracotta)
                                .frame(width: 24, height: 24)
                                .background(Color.terracotta.opacity(0.15), in: Circle())
                            Text(step.text)
                                .font(.outfit(size: 14))
                                .foregroundStyle(Color.charcoalMid)
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Pairing card

    private var pairingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Text("✦").foregroundStyle(Color.terracotta)
                    Text("AI SUGGESTS PAIRING WITH")
                        .font(.outfit(size: 12, weight: .bold))
                        .tracking(0.7)
                        .foregroundStyle(Color.terracotta)
                }
                Spacer()
                Button {
                    Task { await controller.regeneratePairings() }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.terracotta)
                        .frame(width: 28, height: 28)
                        .background(Color.terracotta.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(controller.isLoadingPairings)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if controller.isLoadingPairings && controller.pairings.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Finding pairings...")
                        .font(.outfit(size: 12))
                        .foregroundStyle(Color.charcoalLight)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            } else if let error = controller.pairingsErrorMessage {
                Text(error)
                    .font(.outfit(size: 12))
                    .foregroundStyle(Color.terracottaDark)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                let columns: [GridItem] = controller.pairings.count > 1
                    ? [GridItem(.flexible()), GridItem(.flexible())]
                    : [GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(controller.pairings) { pairing in
                        pairingCardTile(pairing)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(
            LinearGradient(colors: [Color.terracotta.opacity(0.09), Color.terracotta.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.terracotta.opacity(0.18), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func pairingCardTile(_ pairing: PairingSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text(pairing.emoji)
                    .font(.system(size: 18))
                    .frame(width: 36, height: 36)
                    .background(Color.terracotta.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(pairing.name)
                    .font(.lora(size: 13, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(pairing.reason)
                .font(.outfit(size: 11))
                .foregroundStyle(Color.charcoalLight)

            if pairing.linkedRecipeId != nil {
                HStack(spacing: 3) {
                    Text("See Recipe")
                    Image(systemName: "arrow.right")
                }
                .font(.outfit(size: 11, weight: .semibold))
                .foregroundStyle(Color.terracotta)
            } else {
                Text("Suggestion only")
                    .font(.outfit(size: 11))
                    .foregroundStyle(Color.charcoalPale)
            }
        }
        .padding(12)
        .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.terracotta.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Regenerate / Save + Share

    private var regenerateOrSaveShareRow: some View {
        Group {
            if controller.recipe.canRegenerate {
                Button {
                    Task { await controller.regenerate() }
                } label: {
                    HStack(spacing: 8) {
                        if controller.isRegenerating {
                            ProgressView()
                            Text("Creating a new variation…")
                        } else {
                            Text("✦")
                            Text("Regenerate with AI")
                        }
                    }
                    .font(.outfit(size: 14, weight: .semibold))
                    .foregroundStyle(Color.terracotta)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.terracotta.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.terracotta.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(controller.isRegenerating)
            } else {
                HStack(spacing: 12) {
                    Button {
                        Task { await controller.toggleSave() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: controller.isSaved ? "bookmark.fill" : "bookmark")
                            Text(controller.isSaved ? "Saved" : "Save Recipe")
                        }
                        .font(.outfit(size: 14, weight: .semibold))
                        .foregroundStyle(controller.isSaved ? Color.sage : Color.charcoalMid)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(controller.isSaved ? Color.sage.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(controller.isSaved ? Color.sage.opacity(0.35) : Color.creamBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(controller.isTogglingSave)

                    ShareLink(item: controller.recipe.title) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.outfit(size: 14, weight: .semibold))
                        .foregroundStyle(Color.charcoalMid)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))
                    }
                }
            }
        }
    }

    // MARK: - Start Cooking

    private var startCookingButton: some View {
        Button {
            router.push(.cookMode(controller.recipe))
        } label: {
            Text("Start Cooking")
                .font(.outfit(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.terracotta, in: Capsule())
                .softShadow()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Comments

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Comments")
                    .font(.lora(size: 18, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                Spacer()
                Text("\(controller.comments.count)")
                    .font(.outfit(size: 13))
                    .foregroundStyle(Color.charcoalLight)
            }

            commentInputRow

            if controller.isLoadingComments {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                if let error = controller.commentsErrorMessage {
                    Text(error)
                        .font(.outfit(size: 12))
                        .foregroundStyle(Color.terracottaDark)
                }
                VStack(spacing: 12) {
                    ForEach(controller.comments) { comment in
                        commentRow(comment)
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete this comment?",
            isPresented: Binding(get: { commentToDelete != nil }, set: { if !$0 { commentToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete comment", role: .destructive) {
                if let comment = commentToDelete {
                    Task { await controller.deleteComment(comment) }
                }
                commentToDelete = nil
            }
            Button("Cancel", role: .cancel) { commentToDelete = nil }
        }
    }

    private var commentInputRow: some View {
        Group {
            if let user = auth.currentUser {
                HStack(spacing: 12) {
                    avatarInitial(name: user.displayName, colorHex: user.avatarColorHex, diameter: 32)

                    HStack(spacing: 8) {
                        TextField("Add a comment…", text: $controller.commentInput)
                            .font(.outfit(size: 14))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.charcoal.opacity(0.05), in: Capsule())
                            .overlay(Capsule().stroke(Color.creamBorder, lineWidth: 1))
                            .onSubmit { Task { await controller.postComment(author: user) } }

                        Button {
                            Task { await controller.postComment(author: user) }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.terracotta, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(controller.commentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || controller.isPostingComment)
                    }
                }
            } else {
                HStack {
                    Text("Sign in to join the conversation.")
                        .font(.outfit(size: 13))
                        .foregroundStyle(Color.charcoalLight)
                    Spacer()
                    Button("Sign In") {
                        router.signOut()
                    }
                    .font(.outfit(size: 13, weight: .semibold))
                    .foregroundStyle(Color.terracotta)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.charcoal.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func canDelete(_ comment: RecipeComment) -> Bool {
        guard let me = auth.currentUser else { return false }
        return comment.authorId == me.id || me.role == .admin
    }

    private func commentRow(_ comment: RecipeComment) -> some View {
        let author = controller.commentAuthors[comment.authorId]
        return HStack(alignment: .top, spacing: 12) {
            avatarInitial(name: author?.displayName ?? "?", colorHex: author?.avatarColorHex ?? "#9C8F8A", diameter: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("@\(author?.username ?? "unknown")")
                        .font(.outfit(size: 13, weight: .semibold))
                        .foregroundStyle(Color.charcoal)
                    Text(comment.createdAt, format: .relative(presentation: .named))
                        .font(.outfit(size: 11))
                        .foregroundStyle(Color.charcoalPale)
                    Spacer(minLength: 0)
                    if canDelete(comment) {
                        Button {
                            commentToDelete = comment
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.charcoalPale)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(comment.text)
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoalMid)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .softShadow()
        }
    }

    private func avatarInitial(name: String, colorHex: String, diameter: CGFloat) -> some View {
        Circle()
            .fill(Color(hex: colorHex))
            .frame(width: diameter, height: diameter)
            .overlay(
                Text(String(name.prefix(1)).uppercased())
                    .font(.lora(size: diameter * 0.4, weight: .bold))
                    .foregroundStyle(.white)
            )
    }

    // MARK: - Toast

    private func toast(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.sage)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.outfit(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(controller.recipe.title)
                    .font(.outfit(size: 11))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.charcoal, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
    }
}

#Preview {
    NavigationStack {
        RecipeOverviewScreen(recipe: MockData.spaghettiPomodoro)
    }
    .environment(AppRouter())
    .environment(AuthController())
    .environment(GroceryController())
}

#Preview("AI-generated recipe") {
    NavigationStack {
        RecipeOverviewScreen(recipe: MockData.aiVariations[0])
    }
    .environment(AppRouter())
    .environment(AuthController())
    .environment(GroceryController())
}
