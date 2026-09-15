//
//  CustomBackButton.swift
//  CookAI
//
//  Reusable circular back button for screens with a custom header (system
//  navigation bar hidden). Matches the prototype's floating white circular
//  icon-button style used across detail screens.
//

import SwiftUI

struct CustomBackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.charcoal)
                .frame(width: 36, height: 36)
                .background(Color.white, in: Circle())
                .softShadow()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CustomBackButton(action: {})
        .padding()
        .background(Color.cream)
}
