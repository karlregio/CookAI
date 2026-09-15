//
//  ComingSoonScreen.swift
//  CookAI
//
//  Reusable placeholder destination for any Route not yet built. Custom
//  header (system nav bar hidden) with a custom back button, matching the
//  prototype's fully custom screen chrome.
//

import SwiftUI

struct ComingSoonScreen: View {
    let title: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 12) {
                Text(title)
                    .font(.lora(size: 22, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                    .multilineTextAlignment(.center)

                Text("Coming in the final release")
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoalLight)
            }
            .padding(.horizontal, 32)

            VStack {
                HStack {
                    CustomBackButton { dismiss() }
                    Spacer()
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        ComingSoonScreen(title: "AI Generate")
    }
}
