//
//  CookAILogoMark.swift
//  CookAI
//
//  The rounded terracotta "pot + steam + sparkle" logo mark used on the
//  splash screen and the login header. Drawn with Canvas so both sizes
//  scale from the same 52×52 coordinate space as the prototype's SVG.
//

import SwiftUI

struct CookAILogoMark: View {
    var containerSize: CGFloat = 96
    var iconSize: CGFloat? = nil
    var cornerRadius: CGFloat = 28

    private var resolvedIconSize: CGFloat {
        iconSize ?? containerSize * (52.0 / 96.0)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.terracotta)
            .frame(width: containerSize, height: containerSize)
            .overlay {
                CookAILogoGlyph()
                    .frame(width: resolvedIconSize, height: resolvedIconSize)
            }
            .shadow(color: Color.terracotta.opacity(0.35), radius: 16, x: 0, y: 8)
    }
}

/// Ports the splash-screen SVG (pot silhouette + three rising steam lines + two sparkles)
/// from a 52×52 viewBox onto a Canvas so it scales cleanly at any size.
private struct CookAILogoGlyph: View {
    var tint: Color = .white

    var body: some View {
        Canvas { context, size in
            let scale = size.width / 52

            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * scale, y: y * scale)
            }

            // Pot body
            var pot = Path()
            pot.move(to: pt(10, 26))
            pot.addLine(to: pt(10, 38))
            pot.addCurve(to: pt(15.3, 43), control1: pt(10, 40.65), control2: pt(12.35, 43))
            pot.addLine(to: pt(36.7, 43))
            pot.addCurve(to: pt(42, 38), control1: pt(39.65, 43), control2: pt(42, 40.65))
            pot.addLine(to: pt(42, 26))
            pot.closeSubpath()
            context.fill(pot, with: .color(tint.opacity(0.2)))
            context.stroke(pot, with: .color(tint), style: StrokeStyle(lineWidth: 2 * scale, lineJoin: .round))

            // Rim + three rising steam/skewer lines
            var lines = Path()
            lines.move(to: pt(10, 26)); lines.addLine(to: pt(42, 26))
            lines.move(to: pt(17, 26)); lines.addLine(to: pt(17, 16))
            lines.move(to: pt(26, 26)); lines.addLine(to: pt(26, 12))
            lines.move(to: pt(35, 26)); lines.addLine(to: pt(35, 16))
            context.stroke(lines, with: .color(tint), style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round))

            // Sparkles
            var sparkle1 = Path()
            sparkle1.move(to: pt(8, 12)); sparkle1.addLine(to: pt(9.5, 15)); sparkle1.addLine(to: pt(8, 18)); sparkle1.addLine(to: pt(6.5, 15))
            sparkle1.closeSubpath()
            context.fill(sparkle1, with: .color(tint.opacity(0.6)))

            var sparkle2 = Path()
            sparkle2.move(to: pt(44, 8)); sparkle2.addLine(to: pt(45, 10)); sparkle2.addLine(to: pt(46, 8)); sparkle2.addLine(to: pt(45, 6))
            sparkle2.closeSubpath()
            context.fill(sparkle2, with: .color(tint.opacity(0.5)))
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        CookAILogoMark()
        CookAILogoMark(containerSize: 56, iconSize: 30, cornerRadius: 16)
    }
    .padding()
    .background(Color.cream)
}
