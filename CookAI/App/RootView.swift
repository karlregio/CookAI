//
//  RootView.swift
//  CookAI
//
//  Switches between the three app phases: splash → auth → main. Owns the
//  AppRouter and AuthController for the whole app lifetime and injects them
//  into the environment.
//

import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()
    @State private var auth = AuthController()

    var body: some View {
        Group {
            switch router.phase {
            case .splash:
                SplashScreen()
            case .auth:
                LoginScreen()
            case .main:
                MainTabView()
            }
        }
        .environment(router)
        .environment(auth)
        .onAppear {
            auth.onSignedOut = { router.signOut() }
        }
    }
}

#Preview {
    RootView()
}
