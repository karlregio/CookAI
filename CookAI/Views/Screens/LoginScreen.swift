//
//  LoginScreen.swift
//  CookAI
//
//  Replicates the prototype's LoginScreen (App.tsx ~lines 3458–3634): warm
//  gradient header band, login/sign-up mode switch, email/password fields
//  with show/hide toggle, "Forgot password?", prototype quick-fill tips, and
//  "Continue as Guest". Deviates from the prototype in one place on purpose:
//  submitting with empty fields shows an inline validation message instead
//  of silently doing nothing.
//

import SwiftUI

struct LoginScreen: View {
    private enum Mode {
        case login
        case signUp
    }

    private enum Field: Hashable {
        case name
        case email
        case password
    }

    @Environment(AppRouter.self) private var router
    @Environment(AuthController.self) private var auth

    @State private var mode: Mode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var showPassword = false
    @State private var validationMessage: String?
    @FocusState private var focusedField: Field?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                content
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: auth.currentUser) { _, newValue in
            if newValue != nil {
                router.completeSignIn()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        LinearGradient(colors: [Color(hex: "#F2E6D8"), .cream], startPoint: .top, endPoint: .bottom)
            .frame(height: 192)
            .overlay(alignment: .bottom) {
                CookAILogoMark(containerSize: 56, iconSize: 30, cornerRadius: 16)
                    .padding(.bottom, 24)
            }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(mode == .login ? "Welcome back" : "Create account")
                .font(.lora(size: 24, weight: .semibold))
                .foregroundStyle(Color.charcoal)
                .padding(.bottom, 4)

            Text(mode == .login ? "Sign in to your CookAI account" : "Join the CookAI community")
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoalLight)
                .padding(.bottom, 24)

            modeToggle
                .padding(.bottom, 24)

            fields
                .padding(.bottom, validationMessage == nil ? 16 : 8)

            if let validationMessage {
                Text(validationMessage)
                    .font(.outfit(size: 12, weight: .medium))
                    .foregroundStyle(Color.terracottaDark)
                    .padding(.bottom, 8)
            }

            prototypeTip
                .padding(.bottom, 20)

            primaryButton
                .padding(.bottom, 24)

            guestLink
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    private var fields: some View {
        VStack(spacing: 16) {
            if mode == .signUp {
                labeledField(label: "Your name") {
                    TextField("Alex Rivera", text: $name)
                        .focused($focusedField, equals: .name)
                }
            }

            labeledField(label: "Email") {
                TextField("you@example.com", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
            }
            .onChange(of: email) { _, _ in validationMessage = nil }

            labeledField(label: "Password") {
                HStack(spacing: 8) {
                    Group {
                        if showPassword {
                            TextField("••••••••", text: $password)
                        } else {
                            SecureField("••••••••", text: $password)
                        }
                    }
                    .tint(Color.charcoal)
                    .focused($focusedField, equals: .password)
                    .onSubmit { Task { await submit() } }

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(Color.charcoalLight)
                    }
                    .buttonStyle(.plain)
                }
            }
            .onChange(of: password) { _, _ in validationMessage = nil }

            if mode == .login {
                HStack {
                    Spacer()
                    Button("Forgot password?") {}
                        .font(.outfit(size: 13))
                        .foregroundStyle(Color.terracotta)
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func labeledField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.outfit(size: 11, weight: .semibold))
                .foregroundStyle(Color.charcoalMid)

            content()
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoal)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Mode toggle

    private var modeToggle: some View {
        HStack(spacing: 4) {
            toggleButton(title: "Log In", isActive: mode == .login) {
                mode = .login
                validationMessage = nil
            }
            toggleButton(title: "Sign Up", isActive: mode == .signUp) {
                mode = .signUp
                validationMessage = nil
            }
        }
        .padding(4)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func toggleButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.outfit(size: 14, weight: .semibold))
                .foregroundStyle(isActive ? .white : Color.charcoalLight)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isActive ? Color.terracotta : Color.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Prototype tip

    private var prototypeTipText: AttributedString {
        var label = AttributedString("Prototype tip: ")
        label.font = .outfit(size: 11, weight: .semibold)
        label.foregroundColor = Color.sage

        var body = AttributedString("Any password works. Tap a quick-fill below:")
        body.font = .outfit(size: 11)
        body.foregroundColor = Color.charcoalMid

        label.append(body)
        return label
    }

    private var prototypeTip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(prototypeTipText)

            HStack(spacing: 8) {
                quickFillButton(title: "🛡 Fill Admin", tint: .terracotta) {
                    email = "admin@cookai.com"
                    password = "admin123"
                    mode = .login
                    validationMessage = nil
                }
                quickFillButton(title: "👤 Fill User", tint: .sage) {
                    email = "alex@example.com"
                    password = "hello123"
                    mode = .login
                    validationMessage = nil
                }
            }
        }
        .padding(12)
        .background(Color.sage.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.sage.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func quickFillButton(title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.outfit(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(tint.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(tint.opacity(0.25), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Primary button + guest link

    private var primaryButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack(spacing: 8) {
                if auth.isLoading {
                    ProgressView()
                        .tint(.white)
                    Text("Processing...")
                } else {
                    Text(mode == .login ? "Log In" : "Create Account")
                }
            }
            .font(.outfit(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.terracotta, in: Capsule())
            .softShadow()
        }
        .buttonStyle(.plain)
        .disabled(auth.isLoading)
    }

    private var guestLink: some View {
        HStack {
            Spacer()
            Button {
                router.completeSignIn()
            } label: {
                Text("Continue as Guest")
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoalLight)
                    .underline()
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Submit

    private func submit() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            validationMessage = "Please enter both an email and password to continue."
            return
        }

        if mode == .signUp {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                validationMessage = "Please enter your name to create an account."
                return
            }
            await auth.signUp(name: trimmedName, email: trimmedEmail, password: password)
        } else {
            await auth.signIn(email: trimmedEmail, password: password)
        }

        validationMessage = auth.errorMessage
    }
}

#Preview {
    LoginScreen()
        .environment(AppRouter())
        .environment(AuthController())
}
