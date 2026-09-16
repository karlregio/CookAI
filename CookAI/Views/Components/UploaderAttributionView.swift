//
//  UploaderAttributionView.swift
//  CookAI
//
//  Ports UploaderAttribution from App.tsx (~lines 537–603): an avatar circle
//  with initials (or a sparkle mark for CookAI Official), the display name,
//  and a verified checkmark badge. size .sm is the compact card row; .md is
//  the larger detail-screen row with a tinted background pill.
//

import SwiftUI

struct UploaderAttributionView: View {
    enum Size {
        case sm
        case md
    }

    let user: User
    var size: Size = .sm

    private var avatarDiameter: CGFloat { size == .sm ? 16 : 28 }
    private var nameFontSize: CGFloat { size == .sm ? 10 : 13 }
    private var badgeSize: CGFloat { size == .sm ? 10 : 14 }
    private var tint: Color { Color(hex: user.avatarColorHex) }

    private var displayName: String {
        user.isVerified ? user.displayName : "@\(user.username)"
    }

    var body: some View {
        HStack(spacing: 6) {
            avatar

            Text(displayName)
                .font(.outfit(size: nameFontSize, weight: .semibold))
                .foregroundStyle(user.isVerified ? tint : Color.charcoalLight)
                .lineLimit(1)

            verifiedBadge
        }
        .padding(size == .md ? 12 : 0)
        .background(size == .md ? Color.charcoal.opacity(0.035) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: size == .md ? 16 : 0, style: .continuous))
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    user.isVerified
                        ? AnyShapeStyle(LinearGradient(colors: [tint, Color.sageLight], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(tint)
                )

            if user.isVerified {
                Image(systemName: "sparkle")
                    .font(.system(size: avatarDiameter * 0.42, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text(String(user.displayName.prefix(1)).uppercased())
                    .font(.lora(size: avatarDiameter * 0.42, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: avatarDiameter, height: avatarDiameter)
    }

    private var verifiedBadge: some View {
        Group {
            if user.isVerified {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(tint)
            } else {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(Color.charcoalPale)
            }
        }
        .font(.system(size: badgeSize))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        UploaderAttributionView(user: MockData.systemUser, size: .sm)
        UploaderAttributionView(user: MockData.naomiCooks, size: .sm)
        UploaderAttributionView(user: MockData.systemUser, size: .md)
        UploaderAttributionView(user: MockData.naomiCooks, size: .md)
    }
    .padding()
    .background(Color.cream)
}
