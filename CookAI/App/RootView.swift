//
//  RootView.swift
//  CookAI
//
//  Switches between the three app phases: splash → auth → main. Owns the
//  AppRouter, AuthController, and the shared GroceryController for the whole
//  app lifetime and injects them into the environment so any screen can
//  reach them.
//

import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()
    @State private var auth = AuthController()
    @State private var grocery = GroceryController()

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
        .environment(grocery)
        .onAppear {
            auth.onSignedOut = { router.signOut() }
        }
    }
}

#Preview {
    RootView()
}
