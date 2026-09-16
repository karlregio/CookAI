//
//  SearchBar.swift
//  CookAI
//
//  Ports the dashboard search field from App.tsx (~lines 982–1002).
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search recipes..."

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.charcoalLight)

            TextField(placeholder, text: $text)
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoal)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.charcoalPale)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white, in: Capsule())
        .overlay(Capsule().stroke(Color.charcoal.opacity(0.06), lineWidth: 1))
        .softShadow()
    }
}

private struct SearchBarPreview: View {
    @State private var text = ""

    var body: some View {
        SearchBar(text: $text)
            .padding()
            .background(Color.cream)
    }
}

#Preview {
    SearchBarPreview()
}
