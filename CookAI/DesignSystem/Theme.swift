//
//  Theme.swift
//  CookAI
//
//  Design tokens ported from the React/Tailwind prototype (index.css).
//

import SwiftUI

// MARK: - Color

extension Color {
    /// Creates a Color from a hex string like "#D9713C" or "D9713C". Supports optional alpha ("#RRGGBBAA").
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized.removeAll { $0 == "#" }

        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let r, g, b, a: Double
        switch sanitized.count {
        case 8:
            r = Double((value & 0xFF00_0000) >> 24) / 255
            g = Double((value & 0x00FF_0000) >> 16) / 255
            b = Double((value & 0x0000_FF00) >> 8) / 255
            a = Double(value & 0x0000_00FF) / 255
        default:
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
            a = 1
        }

        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

extension Color {
    // Core palette — values from src/index.css :root
    static let cream = Color(hex: "#FDF8F3")
    static let creamCard = Color(hex: "#FEFAF5")
    static let terracotta = Color(hex: "#D9713C")
    static let terracottaLight = Color(hex: "#E8956A")
    static let terracottaDark = Color(hex: "#B85A28")
    static let sage = Color(hex: "#8A9B6E")
    static let sageLight = Color(hex: "#B3C49A")
    static let charcoal = Color(hex: "#2B2420")
    static let charcoalMid = Color(hex: "#5C4F4A")
    static let charcoalLight = Color(hex: "#9C8F8A")

    /// charcoal at 10% opacity — used for hairline borders (--cream-border)
    static let creamBorder = Color.charcoal.opacity(0.1)

    /// STAR_COLOR in App.tsx — amber/gold, distinct from terracotta
    static let starGold = Color(hex: "#C8920A")
}

// MARK: - Fonts

extension Font {
    /// Maps to the "Lora" family (registered PostScript names Lora-Regular / Lora-Medium / Lora-SemiBold / Lora-Bold).
    /// Falls back to the system serif design when the font file isn't registered.
    static func lora(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black:
            name = "Lora-Bold"
        case .semibold:
            name = "Lora-SemiBold"
        case .medium:
            name = "Lora-Medium"
        default:
            name = "Lora-Regular"
        }

        if UIFont.fontNames(forFamilyName: "Lora").isEmpty {
            return .system(size: size, weight: weight, design: .serif)
        }
        return .custom(name, size: size)
    }

    /// Maps to the "Outfit" family (registered PostScript names Outfit-Light / Outfit-Regular / Outfit-Medium / Outfit-SemiBold / Outfit-Bold).
    /// Falls back to the system default design when the font file isn't registered.
    static func outfit(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black:
            name = "Outfit-Bold"
        case .semibold:
            name = "Outfit-SemiBold"
        case .medium:
            name = "Outfit-Medium"
        case .light, .thin, .ultraLight:
            name = "Outfit-Light"
        default:
            name = "Outfit-Regular"
        }

        if UIFont.fontNames(forFamilyName: "Outfit").isEmpty {
            return .system(size: size, weight: weight, design: .default)
        }
        return .custom(name, size: size)
    }
}

// MARK: - Corner radii

enum CookAIRadius {
    static let small: CGFloat = 16
    static let large: CGFloat = 20
}

// MARK: - View modifiers

private struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = CookAIRadius.large

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.cream.opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct GlassButtonModifier: ViewModifier {
    var cornerRadius: CGFloat = CookAIRadius.large

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.cream.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.7), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Replicates the prototype's shadow-[0_1px_8px_rgba(43,36,32,0.07)] utility.
private struct SoftShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.charcoal.opacity(0.07), radius: 4, x: 0, y: 1)
    }
}

extension View {
    /// Replicates .glass-card: ultraThinMaterial + cream tint + white hairline border.
    func glassCard(cornerRadius: CGFloat = CookAIRadius.large) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    /// Replicates .glass-button: ultraThinMaterial + cream tint + white hairline border.
    func glassButton(cornerRadius: CGFloat = CookAIRadius.large) -> some View {
        modifier(GlassButtonModifier(cornerRadius: cornerRadius))
    }

    /// Replicates shadow-[0_1px_8px_rgba(43,36,32,0.07)].
    func softShadow() -> some View {
        modifier(SoftShadowModifier())
    }
}
