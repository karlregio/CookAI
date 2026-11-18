//
//  StepIllustrationView.swift
//  CookAI
//
//  Ports the eight StepIllustration components from App.tsx (~lines
//  2376–2574) as small looping SwiftUI animations: boil (bubbling pot),
//  chop (knife slicing a carrot), heat (pan over a flame), saute (food
//  hopping in a pan), tomato (dropping into a pot), simmer (covered pot),
//  pasta (strands into a pot), toss (pan flip). The parent view restarts these by giving the container an
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
        .frame(width: 130, height: 100)
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

// MARK: - Shared pot drawing

/// A cooking pot: body with rounded bottom, two side handles and a rim.
private struct PotView: View {
    var width: CGFloat = 78
    var height: CGFloat = 44

    private var body_: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 4, style: .continuous)
    }

    var body: some View {
        ZStack(alignment: .top) {
            HStack {
                Capsule().fill(Color.terracotta).frame(width: 12, height: 6)
                Spacer()
                Capsule().fill(Color.terracotta).frame(width: 12, height: 6)
            }
            .frame(width: width + 28)
            .offset(y: 12)

            body_
                .fill(Color.terracotta.opacity(0.22))
                .overlay(body_.stroke(Color.terracotta, lineWidth: 2))
                .frame(width: width, height: height)

            Capsule()
                .fill(Color.terracotta)
                .frame(width: width + 8, height: 5)
        }
        .frame(width: width + 28, height: height)
    }
}

// MARK: - Boil (pot with rising bubbles, steam and flames)

private struct BoilIllustration: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 14) {
                wisp(delay: 0)
                wisp(delay: 0.5)
                wisp(delay: 1.0)
            }
            .frame(height: 20)

            ZStack {
                PotView()
                HStack(spacing: 12) {
                    bubble(size: 7, delay: 0)
                    bubble(size: 5, delay: 0.35)
                    bubble(size: 8, delay: 0.7)
                }
                .offset(y: 6)
            }

            HStack(spacing: 8) {
                flame(delay: 0)
                flame(delay: 0.2)
                flame(delay: 0.4)
            }
        }
        .onAppear { animate = true }
    }

    private func bubble(size: CGFloat, delay: Double) -> some View {
        Circle()
            .stroke(Color.cream.opacity(0.85), lineWidth: 1.5)
            .frame(width: size, height: size)
            .offset(y: animate ? -22 : 8)
            .opacity(animate ? 0 : 1)
            .animation(.easeIn(duration: 1.2).repeatForever(autoreverses: false).delay(delay), value: animate)
    }

    private func wisp(delay: Double) -> some View {
        Capsule()
            .fill(Color.cream.opacity(0.5))
            .frame(width: 4, height: 14)
            .offset(y: animate ? -8 : 6)
            .opacity(animate ? 0 : 0.7)
            .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false).delay(delay), value: animate)
    }

    private func flame(delay: Double) -> some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 14))
            .foregroundStyle(Color.terracotta)
            .scaleEffect(animate ? 1.15 : 0.85)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(delay), value: animate)
    }
}

// MARK: - Shared frying pan drawing

/// A frying pan seen from the side: shallow body with a long handle on the right.
private struct PanView: View {
    var width: CGFloat = 60

    var body: some View {
        HStack(spacing: 0) {
            UnevenRoundedRectangle(topLeadingRadius: 3, bottomLeadingRadius: 14, bottomTrailingRadius: 14, topTrailingRadius: 3, style: .continuous)
                .fill(Color.terracotta.opacity(0.22))
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 3, bottomLeadingRadius: 14, bottomTrailingRadius: 14, topTrailingRadius: 3, style: .continuous)
                        .stroke(Color.terracotta, lineWidth: 2)
                )
                .frame(width: width, height: 18)
            Capsule()
                .fill(Color.terracotta)
                .frame(width: 26, height: 5)
                .offset(y: -4)
        }
    }
}

// MARK: - Chop (knife slicing a carrot on a board)

private struct ChopIllustration: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Cutting board
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.cream.opacity(0.18))
                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Color.cream.opacity(0.55), lineWidth: 1.2))
                .frame(width: 100, height: 14)
                .offset(y: 36)

            // Carrot waiting to be cut
            Capsule()
                .fill(Color.terracotta.opacity(0.75))
                .frame(width: 46, height: 13)
                .offset(x: -16, y: 23)

            // Slices already cut
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Ellipse()
                        .fill(Color.terracotta.opacity(0.6))
                        .frame(width: 6, height: 12)
                }
            }
            .offset(x: 30, y: 24)

            // Knife, hinged at its tip so the handle rocks up and down
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.cream.opacity(0.85))
                    .frame(width: 36, height: 10)
                Capsule()
                    .fill(Color.terracotta)
                    .frame(width: 20, height: 7)
            }
            .frame(width: 56, alignment: .leading)
            .rotationEffect(.degrees(animate ? -24 : 0), anchor: .leading)
            .offset(x: -2, y: 12)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Heat (pan warming over a flickering flame)

private struct HeatIllustration: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 10) {
                heatLine(delay: 0)
                heatLine(delay: 0.25)
                heatLine(delay: 0.5)
            }
            .frame(height: 16)

            PanView(width: 62)
                .offset(x: 12)

            HStack(spacing: 6) {
                flame(delay: 0)
                flame(delay: 0.15)
                flame(delay: 0.3)
            }
        }
        .onAppear { animate = true }
    }

    private func heatLine(delay: Double) -> some View {
        Capsule()
            .fill(Color.cream.opacity(0.5))
            .frame(width: 3, height: 12)
            .offset(y: animate ? -6 : 4)
            .opacity(animate ? 0 : 0.8)
            .animation(.easeOut(duration: 1.1).repeatForever(autoreverses: false).delay(delay), value: animate)
    }

    private func flame(delay: Double) -> some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 16))
            .foregroundStyle(Color.terracotta)
            .scaleEffect(animate ? 1.2 : 0.8, anchor: .bottom)
            .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(delay), value: animate)
    }
}

// MARK: - Saute (food jumping in a pan, spatula stirring)

private struct SauteIllustration: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            PanView(width: 62)
                .offset(x: 12, y: 22)

            // Bits of food hopping in the pan
            piece(color: Color.terracotta.opacity(0.8), x: -24, size: 9, delay: 0)
            piece(color: Color.cream.opacity(0.7), x: -8, size: 7, delay: 0.15)
            piece(color: Color.sage, x: 8, size: 8, delay: 0.3)

            // Spatula
            Capsule()
                .fill(Color.cream.opacity(0.7))
                .frame(width: 6, height: 38)
                .rotationEffect(.degrees(animate ? 18 : -18), anchor: .bottom)
                .offset(x: -2, y: -4)
        }
        .onAppear { animate = true }
    }

    private func piece(color: Color, x: CGFloat, size: CGFloat, delay: Double) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: x, y: animate ? 4 : 18)
            .animation(.easeOut(duration: 0.45).repeatForever(autoreverses: true).delay(delay), value: animate)
    }
}

// MARK: - Tomato (a tomato dropping into a pot with a ripple)

private struct TomatoIllustration: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Ripple on the surface
            Ellipse()
                .stroke(Color.cream.opacity(0.7), lineWidth: 1.5)
                .frame(width: 50, height: 10)
                .scaleEffect(animate ? 1.3 : 0.5)
                .opacity(animate ? 0 : 0.8)
                .offset(y: 2)
                .animation(.easeOut(duration: 1.3).repeatForever(autoreverses: false), value: animate)

            // The tomato, with a little leaf
            ZStack {
                Circle()
                    .fill(Color.terracotta.opacity(0.4))
                    .overlay(Circle().stroke(Color.terracotta, lineWidth: 2))
                    .frame(width: 28, height: 28)
                Capsule()
                    .fill(Color.sage)
                    .frame(width: 10, height: 5)
                    .offset(y: -14)
            }
            .offset(y: animate ? 0 : -42)
            .opacity(animate ? 0.2 : 1)
            .animation(.easeIn(duration: 1.3).repeatForever(autoreverses: false), value: animate)

            PotView()
                .offset(y: 24)
        }
        .onAppear { animate = true }
    }
}

// MARK: - Simmer (covered pot, slow steam, low flame)

private struct SimmerIllustration: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 22) {
                wisp(delay: 0)
                wisp(delay: 0.7)
            }
            .frame(height: 20)

            ZStack(alignment: .top) {
                PotView()
                // Lid with a knob.
                VStack(spacing: 0) {
                    Circle().fill(Color.terracotta).frame(width: 7, height: 7)
                    Capsule().fill(Color.terracotta.opacity(0.55)).frame(width: 76, height: 7)
                }
                .offset(y: -9)
            }

            Image(systemName: "flame.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.terracotta)
                .scaleEffect(animate ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: animate)
        }
        .onAppear { animate = true }
    }

    private func wisp(delay: Double) -> some View {
        Capsule()
            .fill(Color.cream.opacity(0.4))
            .frame(width: 4, height: 16)
            .offset(y: animate ? -10 : 6)
            .opacity(animate ? 0 : 0.8)
            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: false).delay(delay), value: animate)
    }
}

// MARK: - Pasta (strands sliding into a steaming pot)

private struct PastaIllustration: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 20) {
                wisp(delay: 0)
                wisp(delay: 0.6)
            }
            .frame(height: 14)

            ZStack {
                HStack(spacing: 7) {
                    ForEach(0..<5, id: \.self) { index in
                        Capsule()
                            .fill(Color.cream.opacity(0.75))
                            .frame(width: 3, height: 30)
                            .offset(y: animate ? 2 : -34)
                            .opacity(animate ? 0.3 : 1)
                            .animation(.easeIn(duration: 1.1).repeatForever(autoreverses: false).delay(Double(index) * 0.12), value: animate)
                    }
                }
                .offset(y: -6)

                PotView()
            }
        }
        .onAppear { animate = true }
    }

    private func wisp(delay: Double) -> some View {
        Capsule()
            .fill(Color.cream.opacity(0.4))
            .frame(width: 4, height: 12)
            .offset(y: animate ? -8 : 4)
            .opacity(animate ? 0 : 0.8)
            .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false).delay(delay), value: animate)
    }
}

// MARK: - Toss (pan flipping, food flying through the air)

private struct TossIllustration: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            PanView(width: 62)
                .rotationEffect(.degrees(animate ? -10 : 6), anchor: .center)
                .offset(x: 12, y: 26)

            flyer(color: Color.terracotta.opacity(0.85), x: -22, delay: 0)
            flyer(color: Color.cream.opacity(0.75), x: -4, delay: 0.12)
            flyer(color: Color.sage, x: 14, delay: 0.24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    private func flyer(color: Color, x: CGFloat, delay: Double) -> some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .offset(x: x, y: animate ? -26 : 14)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(delay), value: animate)
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
