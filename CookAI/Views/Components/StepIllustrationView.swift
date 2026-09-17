//
//  StepIllustrationView.swift
//  CookAI
//
//  Ports the eight StepIllustration components from App.tsx (~lines
//  2376–2574) as small looping SwiftUI animations: boil (rising bubbles),
//  chop (knife motion), heat (flame flicker), saute (pan stir), tomato
//  (drop-in with a bounce), simmer (looping steam), pasta (drop-in), toss
//  (pan toss). The parent view restarts these by giving the container an
//  `.id(stepIndex)`, which remounts fresh @State and replays every
//  animation — the same trick the prototype uses with `key={stepIndex}`.
//
//  Respects Reduce Motion: falls back to a single static SF Symbol with no
//  animation when the accessibility setting is on.
//

import SwiftUI

struct StepIllustrationView: View {
    let action: StepAction

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                Image(systemName: staticSymbolName)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Color.terracotta)
            } else {
                animatedIllustration
            }
        }
        .frame(width: 90, height: 70)
    }

    @ViewBuilder
    private var animatedIllustration: some View {
        switch action {
        case .boil: BoilIllustration()
        case .chop: ChopIllustration()
        case .heat: HeatIllustration()
        case .saute: SauteIllustration()
        case .tomato: TomatoIllustration()
        case .simmer: SimmerIllustration()
        case .pasta: PastaIllustration()
        case .toss: TossIllustration()
        }
    }

    private var staticSymbolName: String {
        switch action {
        case .boil: return "flame"
        case .chop: return "fork.knife"
        case .heat: return "flame.fill"
        case .saute: return "arrow.triangle.2.circlepath"
        case .tomato: return "circle.fill"
        case .simmer: return "flame"
        case .pasta: return "drop.fill"
        case .toss: return "wind"
        }
    }
}

// MARK: - Boil (rising, fading bubbles)

private struct BoilIllustration: View {
    @State private var animate = false

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.terracotta.opacity(0.2))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.terracotta, lineWidth: 2))
                .frame(width: 64, height: 34)

            HStack(spacing: 10) {
                bubble(delay: 0)
                bubble(delay: 0.25)
                bubble(delay: 0.5)
            }
            .padding(.bottom, 10)
        }
        .onAppear { animate = true }
    }

    private func bubble(delay: Double) -> some View {
        Circle()
            .fill(Color.terracotta.opacity(0.5))
            .frame(width: 6, height: 6)
            .offset(y: animate ? -16 : 0)
            .opacity(animate ? 0 : 1)
            .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: false).delay(delay), value: animate)
    }
}

// MARK: - Chop (knife rocking motion)

private struct ChopIllustration: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.cream.opacity(0.15))
                .overlay(Ellipse().stroke(Color.terracotta, lineWidth: 1.5))
                .frame(width: 34, height: 22)
                .offset(x: -8, y: 12)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.cream.opacity(0.25))
                .overlay(RoundedRectangle(cornerRadius: 2, style: .continuous).stroke(Color.cream.opacity(0.6), lineWidth: 1.2))
                .frame(width: 8, height: 38)
                .rotationEffect(.degrees(animate ? -16 : 16), anchor: .bottom)
                .offset(x: 16, y: -8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Heat (flame flicker)

private struct HeatIllustration: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: -4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color.terracotta)
                .scaleEffect(animate ? 1.1 : 0.9)
                .opacity(animate ? 1 : 0.7)

            Ellipse()
                .fill(Color.terracotta.opacity(0.18))
                .overlay(Ellipse().stroke(Color.terracotta, lineWidth: 1.6))
                .frame(width: 58, height: 18)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Saute (spoon stirring)

private struct SauteIllustration: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.terracotta.opacity(0.15))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.terracotta, lineWidth: 1.8))
                .frame(width: 58, height: 18)
                .offset(y: 16)

            Capsule()
                .fill(Color.cream.opacity(0.6))
                .frame(width: 6, height: 36)
                .rotationEffect(.degrees(animate ? 16 : -16), anchor: .bottom)
                .offset(y: -10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Tomato (drop-in with a bounce)

private struct TomatoIllustration: View {
    @State private var dropped = false

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.terracotta.opacity(0.15))
                .frame(width: 54, height: 14)
                .offset(y: 24)

            Circle()
                .fill(Color.terracotta.opacity(0.3))
                .overlay(Circle().stroke(Color.terracotta, lineWidth: 2))
                .frame(width: 30, height: 30)
                .offset(y: dropped ? 12 : -32)
                .opacity(dropped ? 1 : 0)
        }
        .onAppear {
            withAnimation(.interpolatingSpring(stiffness: 170, damping: 9)) {
                dropped = true
            }
        }
    }
}

// MARK: - Simmer (looping steam wisps)

private struct SimmerIllustration: View {
    @State private var animate = false

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.terracotta.opacity(0.2))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.terracotta, lineWidth: 2))
                .frame(width: 62, height: 32)

            HStack(spacing: 16) {
                steamWisp(delay: 0)
                steamWisp(delay: 0.6)
            }
            .offset(y: -32)
        }
        .onAppear { animate = true }
    }

    private func steamWisp(delay: Double) -> some View {
        Capsule()
            .fill(Color.cream.opacity(0.4))
            .frame(width: 4, height: 16)
            .offset(y: animate ? -14 : 6)
            .opacity(animate ? 0 : 0.8)
            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false).delay(delay), value: animate)
    }
}

// MARK: - Pasta (strands drop-in)

private struct PastaIllustration: View {
    @State private var dropped = false

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.terracotta.opacity(0.2))
                .frame(width: 58, height: 14)
                .offset(y: 26)

            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { _ in
                    Capsule()
                        .fill(Color.cream.opacity(0.55))
                        .frame(width: 3, height: 32)
                }
            }
            .offset(y: dropped ? 10 : -28)
            .opacity(dropped ? 1 : 0)
        }
        .onAppear {
            withAnimation(.interpolatingSpring(stiffness: 160, damping: 10)) {
                dropped = true
            }
        }
    }
}

// MARK: - Toss (pan toss with an airborne bit)

private struct TossIllustration: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.terracotta.opacity(0.15))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.terracotta, lineWidth: 1.8))
                .frame(width: 54, height: 16)
                .offset(y: 18)
                .rotationEffect(.degrees(animate ? 6 : -6), anchor: .bottom)

            Circle()
                .fill(Color.cream.opacity(0.5))
                .frame(width: 8, height: 8)
                .offset(x: animate ? 10 : -10, y: animate ? -24 : -8)
                .opacity(animate ? 0.9 : 0.5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.charcoal.ignoresSafeArea()
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                StepIllustrationView(action: .boil)
                StepIllustrationView(action: .chop)
                StepIllustrationView(action: .heat)
                StepIllustrationView(action: .saute)
            }
            HStack(spacing: 16) {
                StepIllustrationView(action: .tomato)
                StepIllustrationView(action: .simmer)
                StepIllustrationView(action: .pasta)
                StepIllustrationView(action: .toss)
            }
        }
    }
}
