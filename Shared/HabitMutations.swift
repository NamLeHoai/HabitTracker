//
//  HabitMutations.swift
//  HabitTracker (Shared)
//
//  Store-level habit operations that don't need HabitStore's in-memory indices, so they can run
//  from the widget's App Intent. Toggling writes directly to the shared SwiftData store; the
//  snapshot builder recomputes today's snapshot straight from the context after a change.
//

import Foundation
import SwiftData

@MainActor
enum HabitMutations {
    /// Toggle today's completion for a habit id, writing directly to the store. Mirrors the
    /// per-day upsert in HabitStore (one HabitLog row per (habit, day); deleted when value hits 0).
    static func toggleToday(habitID: String, in context: ModelContext) {
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.id == habitID })
        guard let habit = try? context.fetch(descriptor).first else { return }

        let day = DayKey.startOfDay(Date())
        let key = DayKey.key(day)
        let existing = (habit.logs ?? []).first { $0.dayKey == key }
        let current = existing?.count ?? 0
        let newValue = HabitDerivations.toggledValue(habit.spec, current: current)

        if let existing {
            if newValue == 0 { context.delete(existing) } else { existing.count = newValue }
        } else if newValue != 0 {
            context.insert(HabitLog(dayKey: key, dayStart: day, count: newValue, habit: habit))
        }
        try? context.save()
    }

    /// Recompute today's snapshot from the store (used by the widget right after a toggle).
    static func buildSnapshot(from context: ModelContext) -> HabitSnapshot {
        let today = DayKey.startOfDay(Date())
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)])
        let habits = (try? context.fetch(descriptor)) ?? []

        func logs(_ habit: Habit) -> [String: Int] {
            Dictionary((habit.logs ?? []).filter { $0.count != 0 }.map { ($0.dayKey, $0.count) },
                       uniquingKeysWith: { a, _ in a })
        }

        let items = habits
            .filter { HabitDerivations.isScheduled($0.spec, on: today) }
            .map { habit -> HabitSnapshot.Item in
                let v = logs(habit)[DayKey.key(today)] ?? 0
                let done = HabitDerivations.isDone(habit.spec, value: v)
                let progress: Double
                switch habit.goal {
                case .check: progress = done ? 1 : 0
                case .measure(let target, _): progress = target > 0 ? min(1, Double(v) / Double(target)) : 0
                }
                return HabitSnapshot.Item(id: habit.id, icon: habit.icon, name: habit.name,
                                          colorHex: habit.colorHex, done: done, progress: progress)
            }

        let best = habits.map { HabitDerivations.bestStreak($0.spec, logs($0), today: today) }.max() ?? 0
        return HabitSnapshot(dayKey: DayKey.key(today),
                             doneCount: items.filter(\.done).count,
                             total: items.count,
                             bestStreak: best,
                             items: items)
    }
}
