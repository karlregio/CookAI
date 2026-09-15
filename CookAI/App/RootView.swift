//
//  RootView.swift
//  CookAI
//
//  Temporary build-check screen: confirms Theme fonts/colors render correctly
//  and that the mock Services + MockData wiring works end-to-end. Will be
//  replaced by real routing (splash/login/dashboard) as screens are built.
//

import SwiftUI

struct RootView: View {
    @State private var controller = RootController()

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("CookAI")
                    .font(.lora(size: 32, weight: .semibold))
                    .foregroundStyle(Color.charcoal)

                Text(controller.statusMessage)
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoalMid)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    Task { await controller.verifyMockDataPipeline() }
                } label: {
                    HStack(spacing: 8) {
                        if controller.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Verify Mock Data")
                            .font(.outfit(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.terracotta, in: Capsule())
                    .softShadow()
                }
                .disabled(controller.isLoading)
            }
        }
    }
}

#Preview {
    RootView()
}
