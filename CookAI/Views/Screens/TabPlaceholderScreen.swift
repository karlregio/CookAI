//
//  TabPlaceholderScreen.swift
//  CookAI
//
//  Temporary root content for each tab: just the tab title on the cream
//  background, plus one button to push a test Route so the NavigationStack,
//  hidden-tab-bar-on-push, and custom back button can all be verified before
//  the real per-tab screens are built.
//

import SwiftUI

struct TabPlaceholderScreen: View {
    let tab: Tab

    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 16) {
                Text(tab.title)
                    .font(.lora(size: 28, weight: .semibold))
                    .foregroundStyle(Color.charcoal)

                Button {
                    router.push(.comingSoon(title: "\(tab.title) Detail"))
                } label: {
                    Text("Push test screen")
                        .font(.outfit(size: 13, weight: .semibold))
                        .foregroundStyle(Color.terracotta)
                }
                .buttonStyle(.plain)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        TabPlaceholderScreen(tab: .home)
    }
    .environment(AppRouter())
}
