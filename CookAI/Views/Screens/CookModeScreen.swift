//
//  CookModeScreen.swift
//  CookAI
//
//  Ports CookModeScreen from App.tsx (~lines 2578–2829): dark full-screen
//  cooking flow with a segmented step progress bar, animated step
//  illustration, a circular countdown for timed steps, Previous/Next
//  (Next becomes Finish on the last step), a floating Ask AI button, and
//  the post-cook reflection sheet. Steps come from the Recipe passed in via
//  CookSessionController, never a shared/global list.
//
//  Idle timer: disabled while this screen is on-screen and active so the
//  device won't sleep mid-recipe, and explicitly re-enabled in three
//  places so it can never get stuck "always awake": onDisappear (leaving
//  the screen normally), scenePhase going to background/inactive (so a
//  backgrounded app doesn't keep insisting the device stay awake), and
//  scenePhase returning to active only re-disables it if this screen is
//  still the one on screen. If the app is killed outright, iOS tears down
//  the process — isIdleTimerDisabled is process-local, in-memory state, so
//  a fresh launch always starts with it false; there's nothing to "leak"
//  across a kill, only across backgrounding within the same process.
//

import SwiftUI

struct CookModeScreen: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    @State private var controller: CookSessionController
    @State private var showAskAI = false
    @State private var showReflectionSheet = false
    @State private var showExitConfirmation = false

    init(recipe: Recipe) {
        _controller = State(initialValue: CookSessionController(recipe: recipe))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            stepContent
            navigationButtons
        }
        .background(Color.charcoal.ignoresSafeArea())
        .overlay(alignment: .bottomTrailing) { askAIButton }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            controller.pauseCountdown()
        }
        .onChange(of: scenePhase) { _, newPhase in
            UIApplication.shared.isIdleTimerDisabled = (newPhase == .active)
        }
        .alert("Leave Cook Mode?", isPresented: $showExitConfirmation) {
            Button("Keep Cooking", role: .cancel) {}
            Button("Leave", role: .destructive) { router.pop() }
        } message: {
            Text("If you leave now, your progress on this recipe will be lost.")
        }
        .sheet(isPresented: $showAskAI) {
            AskAISheet(
                currentStepText: controller.currentStep?.text ?? "",
                messages: controller.chatHistory,
                inputText: $controller.chatInput,
                isSending: controller.isAskingAI,
                errorMessage: controller.askAIErrorMessage,
                onSend: { text in Task { await controller.askQuestion(text) } },
                onClose: { showAskAI = false }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showReflectionSheet) {
            PostCookReflectionSheet(
                rating: $controller.reflectionRating,
                issueText: $controller.issueText,
                troubleshootResponse: controller.troubleshootResponse,
                isTroubleshooting: controller.isTroubleshooting,
                isSubmitting: controller.isSubmittingReflection,
                onSubmitIssue: { Task { await controller.submitTroubleshoot() } },
                onFinish: { Task { await finishAndReturn() } },
                onSkip: { Task { await finishAndReturn() } }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
        }
    }

    private func finishAndReturn() async {
        let success = await controller.finishCooking()
        if success {
            showReflectionSheet = false
            router.pop()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    if hasUnsavedProgress {
                        showExitConfirmation = true
                    } else {
                        router.pop()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Step \(controller.currentStepIndex + 1) of \(controller.totalSteps)")
                    .font(.outfit(size: 14))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Color.clear.frame(width: 32, height: 32)
            }

            segmentedProgressBar
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
        .padding(.bottom, 16)
    }

    private var segmentedProgressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(controller.totalSteps, 1), id: \.self) { index in
                Capsule()
                    .fill(index <= controller.currentStepIndex ? Color.sage : Color.white.opacity(0.12))
                    .frame(height: 4)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: controller.currentStepIndex)
    }

    // MARK: - Step content

    private var stepContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let step = controller.currentStep {
                    StepIllustrationView(action: step.action)
                        .id(controller.currentStepIndex)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(controller.currentStepIndex + 1)")
                            .font(.outfit(size: 16, weight: .bold))
                            .foregroundStyle(Color.terracotta)
                            .frame(width: 40, height: 40)
                            .background(Color.terracotta.opacity(0.2), in: Circle())

                        Text(step.text)
                            .font(.lora(size: 22, weight: .medium))
                            .foregroundStyle(.white)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if step.timerSeconds != nil {
                        timerSection
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .frame(minHeight: 380)
        }
    }

    private var timerSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(Color.terracotta, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: controller.remainingSeconds)

                Text(formattedTime)
                    .font(.outfit(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 100, height: 100)

            HStack(spacing: 16) {
                Button {
                    controller.toggleTimer()
                } label: {
                    Text(controller.isTimerRunning ? "Pause" : (isTimerStarted ? "Resume" : "Start Timer"))
                        .font(.outfit(size: 14, weight: .medium))
                        .foregroundStyle(Color.terracotta)
                }
                .buttonStyle(.plain)

                if isTimerStarted {
                    Button {
                        controller.resetCountdown()
                    } label: {
                        Text("Reset")
                            .font(.outfit(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 4)
    }

    private var isTimerStarted: Bool {
        guard let remaining = controller.remainingSeconds, let total = controller.currentStep?.timerSeconds else { return false }
        return remaining < total
    }

    /// True whenever leaving would silently discard real progress: a timer
    /// that's running or paused mid-countdown, or having advanced past the
    /// first step. Only step 1 with no timer ever started skips the
    /// confirmation, since there's nothing yet to lose.
    private var hasUnsavedProgress: Bool {
        controller.isTimerRunning || isTimerStarted || controller.currentStepIndex > 0
    }

    private var timerProgress: Double {
        guard let remaining = controller.remainingSeconds, let total = controller.currentStep?.timerSeconds, total > 0 else { return 0 }
        return Double(remaining) / Double(total)
    }

    private var formattedTime: String {
        guard let remaining = controller.remainingSeconds else { return "0:00" }
        return String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            Button {
                controller.goToPreviousStep()
            } label: {
                Text("← Previous")
                    .font(.outfit(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(controller.currentStepIndex == 0)
            .opacity(controller.currentStepIndex == 0 ? 0.3 : 1)

            Button {
                if controller.isLastStep {
                    showReflectionSheet = true
                } else {
                    controller.goToNextStep()
                }
            } label: {
                Text(controller.isLastStep ? "Finish Cooking ✓" : "Next Step →")
                    .font(.outfit(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        controller.isLastStep ? Color.starGold : Color.terracotta,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 36)
    }

    // MARK: - Ask AI floating button

    private var askAIButton: some View {
        Button {
            showAskAI = true
        } label: {
            Text("✦")
                .font(.system(size: 20))
                .foregroundStyle(Color.terracotta)
                .frame(width: 56, height: 56)
                .glassButton(cornerRadius: 28)
                .softShadow()
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 130)
    }
}

#Preview {
    CookModeScreen(recipe: MockData.spaghettiPomodoro)
        .environment(AppRouter())
}
