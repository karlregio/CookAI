//
//  RecipeCard.swift
//  CookAI
//
//  Ports RecipeCard from App.tsx (~lines 605–657): image with an overlaid
//  rating badge, title, uploader attribution, cook time, and difficulty
//  badge. Rating now comes straight off the Recipe model rather than a
//  separately-passed ratings map, since our model already carries it.
//

import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    var uploader: User?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                image
                info
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.charcoal.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var image: some View {
        ZStack(alignment: .bottomLeading) {
            Color(hex: "#E8DDD5")

            AsyncImage(url: recipe.imageURL) { phase in
                switch phase {
                case .success(let loadedImage):
                    loadedImage.resizable().scaledToFill()
                case .failure:
                    Image(systemName: "fork.knife")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(Color.charcoalLight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                default:
                    Color.cream
                }
            }

            if recipe.ratingCount > 0 {
                HStack(spacing: 4) {
                    StarIcon(fill: 1, size: 10)
                    Text(String(format: "%.1f", recipe.ratingAverage))
                        .font(.outfit(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.45), in: Capsule())
                .padding(8)
            }
        }
        .aspectRatio(1.5, contentMode: .fit)
        .clipped()
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(recipe.title)
                .font(.lora(size: 14, weight: .semibold))
                .foregroundStyle(Color.charcoal)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if let uploader {
                UploaderAttributionView(user: uploader, size: .sm)
            }

            HStack {
                Text("⏱ \(recipe.formattedTime)")
                    .font(.outfit(size: 11))
                    .foregroundStyle(Color.charcoalLight)
                Spacer()
                DifficultyBadge(difficulty: recipe.difficulty)
            }
        }
        .padding(12)
        .padding(.bottom, 2)
    }
}

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            RecipeCard(recipe: MockData.spaghettiPomodoro, uploader: MockData.systemUser) {}
            RecipeCard(recipe: MockData.misoGlazedSalmon, uploader: MockData.naomiCooks) {}
        }
        .padding()
    }
    .background(Color.cream)
}
