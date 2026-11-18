//
//  AIGenerateScreen.swift
//  CookAI
//
//  Ports AIGenerateScreen from App.tsx (~lines 1065–1330): ingredient tags,
//  dietary toggles, a spice slider and a Generate button, with a full-screen
//  loading state that rotates through short tips. Adds an optional cuisine
//  picker so you can ask for a dish from a specific country.
//

import SwiftUI

struct AIGenerateScreen: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var controller = AIGenerateController()
    @State private var isSpinning = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            if controller.isGenerating {
                loadingView
            } else {
                form
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: controller.generatedRecipe) { _, recipe in
            guard let recipe else { return }
            // Swap this screen for the new recipe so Back returns to Home.
            router.pop()
            router.push(.recipeOverview(recipe))
        }
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                VStack(alignment: .leading, spacing: 24) {
                    ingredientsSection
                    cuisineSection
                    dietarySection
                    spiceSection
                    if let message = controller.errorMessage {
                        Text(message)
                            .font(.outfit(size: 13, weight: .medium))
                            .foregroundStyle(Color.terracottaDark)
                    }
                    generateButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                CustomBackButton { dismiss() }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            ZStack {
                Circle().fill(Color.terracotta.opacity(0.1)).frame(width: 80, height: 80)
                Text("✦").font(.system(size: 34)).foregroundStyle(Color.terracotta)
            }
            .padding(.top, 4)
            .padding(.bottom, 8)

            Text("AI Recipe Generator")
                .font(.lora(size: 24, weight: .semibold))
                .foregroundStyle(Color.charcoal)
            Text("Tell me what you have and I'll create something delicious.")
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoalLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: Ingredients

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("What ingredients do you have?")
            if !controller.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(controller.tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.outfit(size: 13, weight: .medium))
                            Button {
                                controller.removeTag(tag)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .buttonStyle(.plain)
                        }
                        .foregroundStyle(Color.sage)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.sage.opacity(0.15), in: Capsule())
                    }
                }
            }
            HStack(spacing: 8) {
                TextField("Type an ingredient, then tap Add", text: $controller.ingredientInput)
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoal)
                    .focused($inputFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        controller.commitInput()
                        inputFocused = true
                    }
                    .onChange(of: controller.ingredientInput) { _, text in
                        if text.hasSuffix(",") { controller.commitInput() }
                    }
                Button("Add") {
                    controller.commitInput()
                    inputFocused = true
                }
                .font(.outfit(size: 13, weight: .semibold))
                .foregroundStyle(Color.terracotta)
                .buttonStyle(.plain)
                .disabled(controller.ingredientInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: Cuisine / dietary / spice

    private var cuisineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Cuisine (optional)")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AIGenerateController.cuisineOptions, id: \.self) { cuisine in
                        CategoryChip(title: cuisine, isActive: controller.selectedCuisine == cuisine) {
                            controller.toggleCuisine(cuisine)
                        }
                    }
                }
            }
            if controller.selectedCuisine == nil {
                Text("Nothing selected — the AI will surprise you.")
                    .font(.outfit(size: 12))
                    .foregroundStyle(Color.charcoalLight)
            }
        }
    }

    private var dietarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Dietary restrictions")
            HStack(spacing: 8) {
                ForEach(AIGenerateController.Dietary.allCases) { option in
                    let isOn = controller.dietary.contains(option)
                    Button {
                        controller.toggle(option)
                    } label: {
                        Text(option.rawValue)
                            .font(.outfit(size: 13, weight: .medium))
                            .foregroundStyle(isOn ? Color.white : Color.charcoalMid)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(isOn ? Color.sage : Color.white, in: Capsule())
                            .overlay(Capsule().stroke(isOn ? Color.sage : Color.creamBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var spiceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("Spice level")
                Spacer()
                Text(controller.spiceLabel)
                    .font(.outfit(size: 14, weight: .semibold))
                    .foregroundStyle(Color.terracotta)
            }
            Slider(
                value: Binding(
                    get: { Double(controller.spiceLevel) },
                    set: { controller.spiceLevel = Int($0.rounded()) }
                ),
                in: 0...4,
                step: 1
            )
            .tint(Color.terracotta)
        }
    }

    private var generateButton: some View {
        Button {
            inputFocused = false
            Task { await controller.generate() }
        } label: {
            HStack(spacing: 8) {
                Text("✦").font(.system(size: 18))
                Text("Generate Recipe").font(.outfit(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.terracotta, in: Capsule())
            .shadow(color: Color.terracotta.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.outfit(size: 14, weight: .semibold))
            .foregroundStyle(Color.charcoalMid)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.terracotta, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(isSpinning ? 360 : 0))
                    .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isSpinning)
                Text("🍳").font(.system(size: 28))
            }
            .padding(.bottom, 20)
            .onAppear { isSpinning = true }

            Text("Generating your recipe...")
                .font(.lora(size: 20, weight: .semibold))
                .foregroundStyle(Color.charcoal)
            Text(controller.tips[controller.tipIndex])
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoalLight)
                .multilineTextAlignment(.center)
                .id(controller.tipIndex)
                .transition(.opacity)
                .animation(.easeInOut, value: controller.tipIndex)
        }
        .padding(.horizontal, 32)
    }
}

/// Simple wrapping layout for the ingredient tags.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                widest = max(widest, x - spacing)
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        widest = max(widest, x - spacing)
        return CGSize(width: maxWidth.isFinite ? maxWidth : widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    NavigationStack {
        AIGenerateScreen()
    }
    .environment(AppRouter())
}
