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
        .task {
            await auth.restoreSession()
        }
        .onChange(of: router.phase) { _, phase in
            // A login restored during the splash goes straight to the app.
            if phase == .auth, auth.currentUser != nil {
                router.completeSignIn()
            }
            // Bring in the saved grocery list once the user is inside the app.
            if phase == .main {
                Task { await grocery.load() }
            }
        }
        .onAppear {
            auth.onSignedOut = {
                router.signOut()
                grocery.clear()
                Task { await ServiceContainer.shared.recipeRepository.resetSessionState() }
            }
        }
    }
}

#Preview {
    RootView()
}
