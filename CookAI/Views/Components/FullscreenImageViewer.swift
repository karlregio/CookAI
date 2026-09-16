//
//  FullscreenImageViewer.swift
//  CookAI
//
//  Ports FullscreenImageViewer from App.tsx (~lines 790–897): a black
//  fullscreen lightbox with pinch-to-zoom, double-tap to zoom, and
//  drag-down-to-dismiss (or tap the X). Reusable anywhere a recipe photo
//  needs a closer look.
//

import SwiftUI

struct FullscreenImageViewer: View {
    let imageURL: URL?
    let accessibilityLabel: String
    let onClose: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
                        .gesture(magnifyGesture)
                        .simultaneousGesture(dragGesture)
                        .onTapGesture(count: 2, perform: toggleZoom)
                case .failure:
                    Image(systemName: "fork.knife")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.6))
                default:
                    ProgressView().tint(.white)
                }
            }
            .accessibilityLabel(accessibilityLabel)

            VStack {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.white.opacity(0.2), in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)

                Spacer()
            }
        }
        .opacity(dismissOpacity)
        .statusBarHidden()
    }

    private var dismissOpacity: Double {
        guard scale <= 1 else { return 1 }
        return 1 - min(0.6, abs(dragOffset.height) / 400)
    }

    private func toggleZoom() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if scale > 1 {
                scale = 1
                lastScale = 1
                offset = .zero
            } else {
                scale = 2.5
                lastScale = 2.5
            }
        }
    }

    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(1, min(5, lastScale * value))
            }
            .onEnded { _ in
                lastScale = scale
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if scale > 1 {
                    dragOffset = value.translation
                } else if value.translation.height > 0 {
                    dragOffset = value.translation
                }
            }
            .onEnded { value in
                if scale <= 1 && value.translation.height > 120 {
                    onClose()
                } else if scale > 1 {
                    offset.width += dragOffset.width
                    offset.height += dragOffset.height
                    dragOffset = .zero
                } else {
                    withAnimation(.spring()) { dragOffset = .zero }
                }
            }
    }
}

#Preview {
    FullscreenImageViewer(
        imageURL: MockData.spaghettiPomodoro.imageURL,
        accessibilityLabel: MockData.spaghettiPomodoro.title,
        onClose: {}
    )
}
