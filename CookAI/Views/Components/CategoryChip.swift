//
//  CategoryChip.swift
//  CookAI
//
//  Ports the cuisine-filter chip buttons from DashboardScreen in App.tsx
//  (~lines 1006–1036), including the distinct dark "AI Generate" styling.
//

import SwiftUI

struct CategoryChip: View {
    let title: String
    var isAIGenerate: Bool = false
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isAIGenerate {
                    Text("✦").font(.system(size: 12))
                }
                Text(title)
            }
            .font(.outfit(size: 13, weight: .medium))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(backgroundColor, in: Capsule())
            .overlay(Capsule().stroke(Color.creamBorder, lineWidth: showsBorder ? 1 : 0))
            .shadow(color: shadowColor, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        if isAIGenerate { return Color.charcoal }
        return isActive ? Color.terracotta : Color.white
    }

    private var foregroundColor: Color {
        if isAIGenerate || isActive { return .white }
        return Color.charcoalMid
    }

    private var showsBorder: Bool {
        !isAIGenerate && !isActive
    }

    private var shadowColor: Color {
        isActive && !isAIGenerate ? Color.terracotta.opacity(0.3) : .clear
    }
}

#Preview {
    HStack(spacing: 8) {
        CategoryChip(title: "All", isActive: true) {}
        CategoryChip(title: "Italian") {}
        CategoryChip(title: "AI Generate", isAIGenerate: true) {}
    }
    .padding()
    .background(Color.cream)
}
