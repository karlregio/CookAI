//
//  GroceryListScreen.swift
//  CookAI
//
//  Ports GroceryListScreen from App.tsx (~lines 5091–5251): items grouped
//  by category with per-group counts, checkable rows, and a "clear checked"
//  footer. Uses the existing app-level GroceryController from Prompt 3 (via
//  the environment) — not a second local list. Adds two things the
//  prototype didn't have, per Task 3: a manual "Add to List" field and
//  swipe-to-delete (using a List so the native swipe gesture comes for
//  free, restyled to match the rest of the app's card look).
//

import SwiftUI

struct GroceryListScreen: View {
    @Environment(GroceryController.self) private var grocery
    @State private var newItemName = ""

    private let categoryOrder = ["Produce", "Pantry", "Dairy & Eggs", "Meat & Fish", "Other"]

    var body: some View {
        VStack(spacing: 0) {
            header
            if grocery.items.isEmpty {
                emptyState
            } else {
                itemsList
            }
        }
        .background(Color.cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var checkedCount: Int {
        grocery.items.filter(\.isChecked).count
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Grocery List")
                    .font(.lora(size: 24, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                if !grocery.items.isEmpty {
                    Text("\(grocery.items.count - checkedCount) remaining · \(checkedCount) checked")
                        .font(.outfit(size: 14))
                        .foregroundStyle(Color.charcoalLight)
                }
            }
            Spacer()
            Image(systemName: "bag")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.sage)
                .frame(width: 40, height: 40)
                .background(Color.sage.opacity(0.15), in: Circle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.creamBorder).frame(height: 1)
        }
    }

    // MARK: - Grouping

    private var groupedItems: [(category: String, items: [GroceryItem])] {
        let grouped = Dictionary(grouping: grocery.items, by: \.category)
        return categoryOrder.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    // MARK: - List

    private var itemsList: some View {
        List {
            Section {
                addItemRow
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            ForEach(groupedItems, id: \.category) { group in
                Section {
                    ForEach(group.items) { item in
                        itemRow(item)
                            .listRowInsets(EdgeInsets(top: 3, leading: 20, bottom: 3, trailing: 20))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    grocery.remove(item.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    categoryHeader(group.category, items: group.items)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                .listRowBackground(Color.clear)
            }

            if checkedCount > 0 {
                Section {
                    clearCheckedButton
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 20, trailing: 20))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
    }

    private var addItemRow: some View {
        HStack(spacing: 8) {
            TextField("Add an item...", text: $newItemName)
                .font(.outfit(size: 14))
                .foregroundStyle(Color.charcoal)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white, in: Capsule())
                .overlay(Capsule().stroke(Color.creamBorder, lineWidth: 1))
                .onSubmit(addManualItem)

            Button(action: addManualItem) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.sage, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func addManualItem() {
        grocery.addManualItem(newItemName)
        newItemName = ""
    }

    private func categoryHeader(_ category: String, items: [GroceryItem]) -> some View {
        HStack(spacing: 8) {
            Text(category.uppercased())
                .font(.outfit(size: 11, weight: .bold))
                .tracking(1)
                .foregroundStyle(Color.charcoalLight)
            Rectangle().fill(Color.creamBorder).frame(height: 1)
            Text("\(items.filter { !$0.isChecked }.count)/\(items.count)")
                .font(.outfit(size: 11))
                .foregroundStyle(Color.charcoalPale)
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
        .textCase(nil)
    }

    private func itemRow(_ item: GroceryItem) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                grocery.toggle(item.id)
            }
        } label: {
            HStack(spacing: 12) {
                checkbox(isChecked: item.isChecked)

                Text(item.name)
                    .font(.outfit(size: 14))
                    .foregroundStyle(item.isChecked ? Color.charcoalPale : Color.charcoal)
                    .strikethrough(item.isChecked)

                Spacer(minLength: 8)

                Text(item.recipeTitle)
                    .font(.outfit(size: 10, weight: .medium))
                    .foregroundStyle(Color.terracotta)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.terracotta.opacity(0.08), in: Capsule())
                    .frame(maxWidth: 100, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func checkbox(isChecked: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isChecked ? Color.sage : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isChecked ? Color.sage : Color.charcoal.opacity(0.18), lineWidth: 1)
                )
            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 20, height: 20)
    }

    private var clearCheckedButton: some View {
        Button {
            grocery.clearChecked()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                Text("Clear \(checkedCount) checked item\(checkedCount == 1 ? "" : "s")")
            }
            .font(.outfit(size: 14, weight: .semibold))
            .foregroundStyle(Color.charcoalMid)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.creamBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(Color.sage.opacity(0.1)).frame(width: 112, height: 112)
                Image(systemName: "bag")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(Color.sage)
            }

            VStack(spacing: 8) {
                Text("Your grocery list is empty")
                    .font(.lora(size: 17, weight: .semibold))
                    .foregroundStyle(Color.charcoal)
                Text("Tap \"Add to List\" on any recipe's\ningredients to populate your list.")
                    .font(.outfit(size: 14))
                    .foregroundStyle(Color.charcoalLight)
                    .multilineTextAlignment(.center)
            }

            addItemRow
                .padding(.horizontal, 20)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
}

#Preview {
    GroceryListScreen()
        .environment(GroceryController())
}
