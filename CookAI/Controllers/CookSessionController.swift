//
//  CookSessionController.swift
//  CookAI
//
//  Drives CookModeScreen: step navigation, a per-step countdown, the Ask AI
//  chat, and the post-cook reflection. Steps come from the Recipe passed in
//  at init, never a shared/global list. The countdown uses a cancellable
//  async Task loop (not a Timer/RunLoop object) so it can't leak — the view
//  cancels it in onDisappear, and it self-cancels via a weak self check even
//  if that were somehow missed.
//

import Foundation
import Observation

@Observable
final class CookSessionController {
    private let aiService: AIService
    private let recipeRepository: RecipeRepository

    let recipe: Recipe
    let steps: [RecipeStep]
    private(set) var currentStepIndex = 0

    // Countdown
    private(set) var remainingSeconds: Int?
    private(set) var isTimerRunning = false
    private var countdownTask: Task<Void, Never>?

    // Ask AI
    private(set) var chatHistory: [AIChatMessage] = []
    var chatInput = ""
    private(set) var isAskingAI = false
    private(set) var askAIErrorMessage: String?

    // Post-cook reflection
    var reflectionRating = 0
    var issueText = ""
    private(set) var troubleshootResponse: String?
    private(set) var isTroubleshooting = false
    private(set) var isSubmittingReflection = false
    private(set) var reflectionErrorMessage: String?

    init(recipe: Recipe, services: ServiceContainer = .shared) {
        self.recipe = recipe
        self.steps = recipe.steps.sorted { $0.order < $1.order }
        self.aiService = services.aiService
        self.recipeRepository = services.recipeRepository
        self.remainingSeconds = steps.first?.timerSeconds
    }

    deinit {
        countdownTask?.cancel()
    }

    // MARK: - Derived state

    var totalSteps: Int { steps.count }

    var currentStep: RecipeStep? {
        steps.indices.contains(currentStepIndex) ? steps[currentStepIndex] : nil
    }

    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStepIndex + 1) / Double(totalSteps)
    }

    var isLastStep: Bool {
        currentStepIndex == totalSteps - 1
    }

    // MARK: - Step navigation

    func goToNextStep() {
        guard currentStepIndex < totalSteps - 1 else { return }
        currentStepIndex += 1
        resetTimerForCurrentStep()
    }

    func goToPreviousStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
        resetTimerForCurrentStep()
    }

    private func resetTimerForCurrentStep() {
        stopCountdownTask()
        remainingSeconds = currentStep?.timerSeconds
    }

    // MARK: - Countdown

    func toggleTimer() {
        isTimerRunning ? pauseCountdown() : startCountdown()
    }

    func startCountdown() {
        guard !isTimerRunning, let remaining = remainingSeconds, remaining > 0 else { return }
        isTimerRunning = true
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            while true {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                guard let self, self.isTimerRunning else { return }
                guard let remaining = self.remainingSeconds, remaining > 0 else {
                    self.isTimerRunning = false
                    return
                }
                let next = remaining - 1
                self.remainingSeconds = next
                if next <= 0 {
                    self.isTimerRunning = false
                    return
                }
            }
        }
    }

    func pauseCountdown() {
        isTimerRunning = false
        stopCountdownTask()
    }

    func resetCountdown() {
        pauseCountdown()
        remainingSeconds = currentStep?.timerSeconds
    }

    private func stopCountdownTask() {
        countdownTask?.cancel()
        countdownTask = nil
    }

    // MARK: - Ask AI

    func askQuestion(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isAskingAI else { return }

        chatHistory.append(AIChatMessage(id: UUID(), role: .user, text: trimmed, createdAt: Date()))
        chatInput = ""
        isAskingAI = true
        askAIErrorMessage = nil
        defer { isAskingAI = false }
        do {
            let answer = try await aiService.askCookingQuestion(trimmed, recipe: recipe, step: currentStep, history: chatHistory)
            chatHistory.append(AIChatMessage(id: UUID(), role: .assistant, text: answer, createdAt: Date()))
        } catch {
            askAIErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Post-cook reflection

    func submitTroubleshoot() async {
        let trimmed = issueText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isTroubleshooting else { return }
        isTroubleshooting = true
        reflectionErrorMessage = nil
        defer { isTroubleshooting = false }
        do {
            troubleshootResponse = try await aiService.troubleshoot(issue: trimmed, recipe: recipe)
        } catch {
            reflectionErrorMessage = error.localizedDescription
        }
    }

    /// Submits the rating (if any) and always records a CookHistoryEntry —
    /// even when skipped without a rating, unlike the prototype (which
    /// dropped the entry entirely on Skip).
    @discardableResult
    func finishCooking() async -> Bool {
        guard !isSubmittingReflection else { return false }
        isSubmittingReflection = true
        reflectionErrorMessage = nil
        defer { isSubmittingReflection = false }
        do {
            if reflectionRating > 0 {
                _ = try await recipeRepository.submitRating(recipeId: recipe.id, stars: reflectionRating)
            }
            let trimmedNote = issueText.trimmingCharacters(in: .whitespacesAndNewlines)
            let entry = CookHistoryEntry(
                id: UUID(),
                recipeId: recipe.id,
                cookedAt: Date(),
                rating: reflectionRating > 0 ? reflectionRating : nil,
                note: trimmedNote.isEmpty ? nil : trimmedNote
            )
            try await recipeRepository.addHistoryEntry(entry)
            return true
        } catch {
            reflectionErrorMessage = error.localizedDescription
            return false
        }
    }
}
