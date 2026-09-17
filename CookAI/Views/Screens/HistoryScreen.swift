//
//  HistoryScreen.swift
//  CookAI
//
//  Ports HistoryScreen from App.tsx (~lines 3080–3186): a vertical timeline
//  of cook history entries with per-row relative date markers. Deviates
//  from the prototype in one place per Task 2: tapping a row pushes
//  recipeOverview (the prototype's tap only expanded an inline tip), so the
//  AI note/tip is shown inline on the row instead of behind a second tap
//  that would conflict with navigation.
//

import SwiftUI

struct HistoryScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var controller = HistoryController()

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await controller.load() }
        .onChange(of: router.selectedTab) { _, newTab in
            if newTab == .history {
                Task { await controller.load() }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Cook History")
                .font(.lora(size: 24, weight: .semibold))
                .foregroundStyle(Color.charcoal)
            Text("Your culinary journey")
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoalLight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Content

    private var content: some View {
        Group {
            if controller.isLoading && controller.rows.isEmpty {
                loadingState
            } else if let error = controller.errorMessage, controller.rows.isEmpty {
                errorState(error)
            } else if controller.rows.isEmpty {
                emptyState
            } else {
                ScrollView {
                    timeline
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
                .refreshable { await controller.load() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var timeline: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.sage.opacity(0.2))
                .frame(width: 1)
                .padding(.leading, 51)
                .padding(.top, 4)

            VStack(spacing: 20) {
                ForEach(controller.rows) { row in
                    timelineRow(row)
                }
            }
        }
    }

    private func timelineRow(_ row: HistoryRow) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(dateLabel(row.entry.cookedAt))
                    .font(.outfit(size: 11, weight: .semibold))
                    .foregroundStyle(Color.sage)
                Circle()
                    .fill(Color.sage)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 52)
            .padding(.top, 2)

            Button {
                guard let recipe = row.recipe else { return }
                router.push(.recipeOverview(recipe))
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    thumbnail(row.recipe)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.recipe?.title ?? "Recipe unavailable")
                            .font(.lora(size: 14, weight: .semibold))
                            .foregroundStyle(Color.charcoal)

                        if let uploader = row.uploader {
                            UploaderAttributionView(user: uploader, size: .sm)
                        }

                        HStack(spacing: 6) {
                            Text("Cooked · \(dateLabel(row.entry.cookedAt))")
                                .font(.outfit(size: 11))
                                .foregroundStyle(Color.charcoalLight)
                            if let rating = row.entry.rating {
                                StarRatingView(average: Double(rating), count: nil, size: 11, showCount: false)
                            }
                        }

                        if let note = row.entry.note {
                            HStack(alignment: .top, spacing: 4) {
                                Text("💬")
                                Text(note)
                                    .lineLimit(2)
                            }
                            .font(.outfit(size: 12))
                            .foregroundStyle(Color.charcoalMid)
                            .padding(.top, 2)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .softShadow()
            }
            .buttonStyle(.plain)
            .disabled(row.recipe == nil)
        }
    }

    private func thumbnail(_ recipe: Recipe?) -> some View {
        ZStack {
            Color(hex: "#E8DDD5")
            if let recipe {
                AsyncImage(url: recipe.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "fork.knife").foregroundStyle(Color.charcoalLight)
                    default:
                        Color.cream
                    }
                }
            } else {
                Image(systemName: "fork.knife").foregroundStyle(Color.charcoalLight)
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func dateLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("📖").font(.system(size: 36))
            Text("No cooking history yet")
                .font(.outfit(size: 15, weight: .semibold))
                .foregroundStyle(Color.charcoal)
            Text("Finish cooking a recipe and it'll show up here.")
                .font(.outfit(size: 13))
                .foregroundStyle(Color.charcoalLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var loadingState: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.charcoal.opacity(0.06))
                        .frame(height: 88)
                        .redacted(reason: .placeholder)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoalLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await controller.load() }
            } label: {
                Text("Retry")
                    .font(.outfit(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.terracotta, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 64)
    }
}

#Preview {
    NavigationStack {
        HistoryScreen()
    }
    .environment(AppRouter())
}
