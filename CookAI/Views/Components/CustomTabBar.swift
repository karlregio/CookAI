//
//  CustomTabBar.swift
//  CookAI
//
//  Replicates TabBar/TabIcon from App.tsx (~lines 661–786): white background,
//  top hairline border, terracotta active color, charcoalLight inactive, 10pt
//  Outfit Medium labels. Icons are SF Symbols chosen to match each SVG shape
//  (the "cart" icon in the prototype is actually a tote-bag silhouette, so we
//  use "bag"/"bag.fill" rather than "cart").
//

import SwiftUI

struct CustomTabBar: View {
    var active: Tab
    var onSelect: (Tab) -> Void

    private let items: [(tab: Tab, outline: String, filled: String)] = [
        (.home, "house", "house.fill"),
        (.saved, "bookmark", "bookmark.fill"),
        (.grocery, "bag", "bag.fill"),
        (.history, "clock", "clock.fill"),
        (.profile, "person", "person.fill"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tab) { item in
                let isActive = item.tab == active
                Button {
                    onSelect(item.tab)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: isActive ? item.filled : item.outline)
                            .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                            .foregroundStyle(isActive ? Color.terracotta : Color.charcoalLight)
                        Text(item.tab.title)
                            .font(.outfit(size: 10, weight: .medium))
                            .foregroundStyle(isActive ? Color.terracotta : Color.charcoalLight)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            Color.white.overlay(alignment: .top) {
                Rectangle().fill(Color.charcoal.opacity(0.08)).frame(height: 1)
            }
        )
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBar(active: .home, onSelect: { _ in })
    }
    .background(Color.cream)
}
