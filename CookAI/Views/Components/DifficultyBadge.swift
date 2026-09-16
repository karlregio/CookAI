//
//  DifficultyBadge.swift
//  CookAI
//
//  Ports DifficultyBadge from App.tsx (~lines 519–533).
//

import SwiftUI

struct DifficultyBadge: View {
    let difficulty: Difficulty

    var body: some View {
        Text(difficulty.rawValue)
            .font(.outfit(size: 10, weight: .semibold))
            .tracking(0.4)
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor, in: Capsule())
    }

    private var backgroundColor: Color {
        switch difficulty {
        case .easy:
            return Color.sage.opacity(0.15)
        case .medium:
            return Color.terracotta.opacity(0.15)
        case .hard:
            return Color.charcoal.opacity(0.1)
        }
    }

    private var textColor: Color {
        switch difficulty {
        case .easy:
            return Color.sage
        case .medium:
            return Color.terracotta
        case .hard:
            return Color.charcoalMid
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        DifficultyBadge(difficulty: .easy)
        DifficultyBadge(difficulty: .medium)
        DifficultyBadge(difficulty: .hard)
    }
    .padding()
    .background(Color.cream)
}
