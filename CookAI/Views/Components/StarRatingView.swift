//
//  StarRatingView.swift
//  CookAI
//
//  Ports the star rating components from App.tsx (~lines 419–486): a
//  5-pointed star shape, a single star with precise partial fill, and a
//  read-only 5-star row with the average and (optional) rating count.
//

import SwiftUI

/// The prototype's 5-pointed star path, defined on a 20×20 viewBox.
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 20
        let scaleY = rect.height / 20

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY)
        }

        var path = Path()
        path.move(to: point(10, 1.5))
        path.addLine(to: point(12.47, 6.51))
        path.addLine(to: point(18, 7.31))
        path.addLine(to: point(14, 11.21))
        path.addLine(to: point(14.94, 16.71))
        path.addLine(to: point(10, 14.1))
        path.addLine(to: point(5.06, 16.7))
        path.addLine(to: point(6, 11.2))
        path.addLine(to: point(2, 7.3))
        path.addLine(to: point(7.53, 6.5))
        path.closeSubpath()
        return path
    }
}

/// A single star with a precise partial fill (0...1), matching the
/// prototype's clipPath technique.
struct StarIcon: View {
    var fill: Double = 1
    var size: CGFloat = 14

    var body: some View {
        ZStack {
            StarShape()
                .stroke(Color.starGold.opacity(0.35), lineWidth: 1.2)

            StarShape()
                .fill(Color.starGold)
                .mask(
                    HStack(spacing: 0) {
                        Rectangle().frame(width: size * max(0, min(1, fill)))
                        Spacer(minLength: 0)
                    }
                )
        }
        .frame(width: size, height: size)
    }
}

/// Read-only star row: fills each of 5 stars proportionally, with the
/// average and an optional rating count.
struct StarRatingView: View {
    var average: Double
    var count: Int?
    var size: CGFloat = 14
    var showCount: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { position in
                    StarIcon(fill: min(1, max(0, average - Double(position - 1))), size: size)
                }
            }

            Text(String(format: "%.1f", average))
                .font(.outfit(size: max(size - 1, 8), weight: .semibold))
                .foregroundStyle(Color.starGold)

            if showCount, let count {
                Text("(\(count.formatted()))")
                    .font(.outfit(size: max(size - 3, 8)))
                    .foregroundStyle(Color.charcoalPale)
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        StarRatingView(average: 4.7, count: 214)
        StarRatingView(average: 3.2, count: 48, size: 18)
        StarRatingView(average: 5.0, count: nil, showCount: false)
    }
    .padding()
    .background(Color.cream)
}
