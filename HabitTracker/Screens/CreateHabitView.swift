//
//  CreateHabitView.swift
//  HabitTracker
//

import SwiftUI

struct CreateHabitView: View {
    @Environment(HabitStore.self) private var store
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "⭐"
    @State private var colorHex = Palette.coral
    @State private var kind: HabitKind = .build
    @State private var goalMeasure = false
    @State private var target = "8"
    @State private var unit = ""
    @State private var sched = "daily"

    private let icons = ["⭐", "💧", "🏃", "📖", "🧘", "💊", "🌙", "🍎", "💪", "🎸",
                         "✍️", "🧹", "🚭", "🍩", "☕", "🦷", "🚶", "🎨", "💰", "🌿"]
    private let schedules = [("daily", "Every day"), ("weekdays", "Weekdays"),
                            ("weekends", "Weekends"), ("3week", "3× / week")]

    private var color: Color { Color(hex: colorHex) }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }.foregroundStyle(t.sub).font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("New Habit").font(.system(size: 17, weight: .bold, design: .rounded))
                Spacer()
                Color.clear.frame(width: 52)
            }
            .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    preview
                    label("NAME")
                    TextField("e.g. Drink water", text: $name)
                        .padding(15).background(t.card, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(t.sep, lineWidth: 1.5))

                    label("ICON")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 9) {
                            ForEach(icons, id: \.self) { ic in
                                Text(ic).font(.system(size: 22)).frame(width: 46, height: 46)
                                    .background(icon == ic ? color.opacity(0.18) : t.pill,
                                                in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .stroke(icon == ic ? color : .clear, lineWidth: 2))
                                    .onTapGesture { icon = ic }
                            }
                        }
                    }

                    label("COLOR")
                    HStack(spacing: 11) {
                        ForEach(Palette.all, id: \.self) { hex in
                            Circle().fill(Color(hex: hex)).frame(width: 34, height: 34)
                                .overlay(Circle().stroke(t.text, lineWidth: colorHex == hex ? 3 : 0))
                                .scaleEffect(colorHex == hex ? 1.1 : 1)
                                .onTapGesture { colorHex = hex }
                        }
                    }

                    label("TYPE")
                    segmented([("✅ Build", kind == .build), ("🚫 Quit", kind == .quit)]) { key in
                        kind = key.contains("Build") ? .build : .quit
                    }

                    label("GOAL")
                    segmented([("Checkmark", !goalMeasure), ("Measurable", goalMeasure)]) { key in
                        goalMeasure = key == "Measurable"
                    }

                    if goalMeasure {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Target").font(.system(size: 11.5, weight: .semibold)).foregroundStyle(t.sub)
                                TextField("8", text: $target).keyboardType(.numberPad)
                                    .padding(13).background(t.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(t.sep, lineWidth: 1.5))
                            }
                            .frame(width: 110)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Unit").font(.system(size: 11.5, weight: .semibold)).foregroundStyle(t.sub)
                                TextField("glasses", text: $unit)
                                    .padding(13).background(t.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(t.sep, lineWidth: 1.5))
                            }
                        }
                        .padding(.top, 12)
                    }

                    label("SCHEDULE")
                    FlowChips(items: schedules, selected: sched) { sched = $0 }

                    Button(action: save) {
                        Text("Create Habit").font(.system(size: 17, weight: .bold))
                            .foregroundStyle(canSave ? .white : t.faint)
                            .frame(maxWidth: .infinity).padding(.vertical, 17)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(canSave
                                          ? AnyShapeStyle(LinearGradient(colors: [t.acc, Color(hex: "#FFB23E")],
                                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                                          : AnyShapeStyle(t.pill))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                    .padding(.top, 24)
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
        .background(t.bg.ignoresSafeArea())
    }

    private var preview: some View {
        VStack(spacing: 12) {
            Text(icon).font(.system(size: 44)).frame(width: 84, height: 84)
                .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(color.opacity(0.4), lineWidth: 2))
            Text(name.isEmpty ? "New Habit" : name).font(.system(size: 19, weight: .heavy, design: .rounded))
        }
        .frame(maxWidth: .infinity).padding(.top, 8).padding(.bottom, 18)
    }

    private func label(_ s: String) -> some View {
        Text(s).font(.system(size: 13, weight: .bold)).foregroundStyle(t.sub)
            .padding(.top, 20).padding(.bottom, 10).padding(.leading, 2)
    }

    private func segmented(_ options: [(String, Bool)], onPick: @escaping (String) -> Void) -> some View {
        HStack(spacing: 5) {
            ForEach(options, id: \.0) { key, active in
                Text(key).font(.system(size: 14.5, weight: .bold))
                    .foregroundStyle(active ? t.acc : t.sub)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(active ? t.card : .clear, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .shadow(color: active ? t.shadow : .clear, radius: 6, y: 3)
                    .onTapGesture { onPick(key) }
            }
        }
        .padding(4).background(t.pill, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let schedule: Schedule
        switch sched {
        case "weekdays": schedule = .week([1, 2, 3, 4, 5])
        case "weekends": schedule = .week([0, 6])
        case "3week": schedule = .week([1, 3, 5])
        default: schedule = .daily
        }
        let goal: Goal = goalMeasure
            ? .measure(target: max(1, Int(target) ?? 1), step: 1)
            : .check
        store.createHabit(name: trimmed, icon: icon, colorHex: colorHex, kind: kind,
                          schedule: schedule, goal: goal, unit: goalMeasure ? unit : "")
        dismiss()
    }
}

/// Wrapping chip row for the schedule options.
private struct FlowChips: View {
    let items: [(String, String)]
    let selected: String
    let onPick: (String) -> Void
    @Environment(\.theme) private var t

    var body: some View {
        HStack(spacing: 9) {
            ForEach(items, id: \.0) { key, title in
                let active = selected == key
                Text(title).font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(active ? .white : t.sub)
                    .padding(.horizontal, 15).padding(.vertical, 9)
                    .background(active ? t.acc : t.pill, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .onTapGesture { onPick(key) }
            }
        }
    }
}
