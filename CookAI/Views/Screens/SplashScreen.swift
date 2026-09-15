//
//  SplashScreen.swift
//  CookAI
//
//  Replicates the prototype's SplashScreen (App.tsx ~lines 3402–3454): logo
//  mark, wordmark, subtitle, and pulsing loading dots, with a staggered
//  fade/scale entrance. Auto-advances to the login screen after 2.2s.
//

import SwiftUI

struct SplashScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 20) {
                CookAILogoMark()
                    .scaleEffect(appear ? 1 : 0.9)
                    .opacity(appear ? 1 : 0)
                    .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.7), value: appear)

                VStack(spacing: 8) {
                    wordmark
                        .opacity(appear ? 1 : 0)
                        .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.8).delay(0.15), value: appear)

                    Text("Your AI-powered kitchen companion")
                        .font(.outfit(size: 14))
                        .foregroundStyle(Color.charcoalLight)
                        .opacity(appear ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(0.3), value: appear)
                }
            }
            .scaleEffect(appear ? 1 : 0.9)
            .opacity(appear ? 1 : 0)
            .animation(.easeOut(duration: 0.6), value: appear)

            VStack {
                Spacer()
                LoadingDots()
                    .opacity(appear ? 1 : 0)
                    .animation(.easeInOut(duration: 0.6).delay(0.8), value: appear)
                    .padding(.bottom, 64)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            appear = true
            Task {
                try? await Task.sleep(for: .seconds(2.2))
                router.finishSplash()
            }
        }
    }

    private var wordmark: some View {
        var wordmarkText = AttributedString("CookAI")
        wordmarkText.foregroundColor = Color.charcoal
        if let aiRange = wordmarkText.range(of: "AI") {
            wordmarkText[aiRange].foregroundColor = Color.terracotta
        }
        return Text(wordmarkText)
            .font(.lora(size: 36, weight: .bold))
            .kerning(-0.5)
    }
}

private struct LoadingDots: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.terracotta.opacity(0.4))
                    .frame(width: 6, height: 6)
                    .scaleEffect(animate ? 1.15 : 1)
                    .opacity(animate ? 1 : 0.6)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(Double(index) * 0.2),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

#Preview {
    SplashScreen()
        .environment(AppRouter())
}
