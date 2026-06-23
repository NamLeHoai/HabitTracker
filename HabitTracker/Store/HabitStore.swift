//
//  HabitStore.swift
//  HabitTracker
//
//  The single source of truth for habits, logs and moods. It loads everything from the
//  model context into in-memory indices once, exposes CACHED derived stats, and recomputes
//  only on mutation — so SwiftUI `body` never triggers a 400-day scan or a fresh query.
//

import Foundation
import SwiftData
import Observation
import WidgetKit

@Observable
final class HabitStore {
    @ObservationIgnored private let context: ModelContext

    private(set) var habits: [Habit] = []
    private(set) var statsByHabit: [String: HabitStats] = [:]
    private(set) var global: GlobalStats = .empty
    private(set) var moodIndex: [String: Int] = [:]

    /// Set when a badge is newly unlocked; the UI shows a one-time celebration then clears it.
    var pendingAchievement: Achievement?

    /// habitID -> (dayKey -> count). Authoritative in-memory view used by all derivations.
    /// Observation-tracked (NOT ignored): Today's rows read completion state from here, so a
    /// toggle must notify SwiftUI. Reassigning a subscript triggers the @Observable setter.
    private var logIndex: [String: [String: Int]] = [:]

    init(context: ModelContext) {
        self.context = context
    }

    /// Local midnight "now". Computed per access so the app rolls over at midnight.
    var today: Date { DayKey.startOfDay(Date()) }

    // MARK: - Loading

    func loadAndSeedIfNeeded() {
        load()
        let defaults = AppGroup.defaults
        if habits.isEmpty && !defaults.bool(forKey: "didSeed") {
            SeedData.seed(into: context)
            defaults.set(true, forKey: "didSeed")
            load()
        }
    }

    func load() {
        let habitDescriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        habits = (try? context.fetch(habitDescriptor)) ?? []

        logIndex = [:]
        for habit in habits {
            var map: [String: Int] = [:]
            for log in (habit.logs ?? []) where log.count != 0 {
                map[log.dayKey] = log.count
            }
            logIndex[habit.id] = map
        }

        let moods = (try? context.fetch(FetchDescriptor<MoodEntry>())) ?? []
        moodIndex = [:]
        for mood in moods { moodIndex[mood.dayKey] = mood.value }

        recompute()
    }

    // MARK: - Reads (O(1), no scanning)

    func logs(for habit: Habit) -> [String: Int] { logIndex[habit.id] ?? [:] }

    func value(_ habit: Habit, on date: Date) -> Int {
        logIndex[habit.id]?[DayKey.key(date)] ?? 0
    }

    func isDone(_ habit: Habit, on date: Date) -> Bool {
        HabitDerivations.isDone(habit.spec, value: value(habit, on: date))
    }

    func isScheduled(_ habit: Habit, on date: Date) -> Bool {
        HabitDerivations.isScheduled(habit.spec, on: date)
    }

    func stats(for habit: Habit) -> HabitStats { statsByHabit[habit.id] ?? HabitStats() }

    var todayHabits: [Habit] {
        let d = today
        return habits.filter { HabitDerivations.isScheduled($0.spec, on: d) }
    }

    var todayMood: Int { moodIndex[DayKey.key(today)] ?? 0 }

    /// Per-habit 18×7 heat grid, computed on demand (used by the detail screen, presented one at a time).
    func heatGrid(for habit: Habit) -> [[Int]] {
        HabitDerivations.heatGrid(items: [], spec: habit.spec, logs: logs(for: habit), today: today)
    }

    // MARK: - Mutations

    func toggleToday(_ habit: Habit) {
        let day = today
        let key = DayKey.key(day)
        let current = logIndex[habit.id]?[key] ?? 0
        let newValue = HabitDerivations.toggledValue(habit.spec, current: current)
        writeLog(habit, dayKey: key, dayStart: day, value: newValue)
        recompute()
    }

    func setMood(_ value: Int) {
        let day = today
        let key = DayKey.key(day)
        moodIndex[key] = value
        let descriptor = FetchDescriptor<MoodEntry>(predicate: #Predicate<MoodEntry> { $0.dayKey == key })
        if let existing = try? context.fetch(descriptor).first {
            existing.value = value
        } else {
            context.insert(MoodEntry(dayKey: key, dayStart: day, value: value))
        }
        try? context.save()
        // Mood does not feed habit stats — no recompute required.
    }

    func createHabit(name: String, icon: String, colorHex: String, kind: HabitKind,
                     schedule: Schedule, goal: Goal, unit: String,
                     reminderEnabled: Bool = false, reminderHour: Int = 9, reminderMinute: Int = 0) {
        let order = (habits.map(\.sortOrder).max() ?? 0) + 1
        let habit = Habit(name: name, icon: icon, colorHex: colorHex, kind: kind,
                          schedule: schedule, goal: goal, unit: unit, sortOrder: order,
                          reminderEnabled: reminderEnabled, reminderHour: reminderHour, reminderMinute: reminderMinute)
        context.insert(habit)
        try? context.save()
        NotificationManager.reschedule(for: habit)
        load()
    }

    /// Edit an existing habit in place, then reschedule its reminder. Mirrors the field mapping in `Habit.init`.
    func updateHabit(_ habit: Habit, name: String, icon: String, colorHex: String, kind: HabitKind,
                     schedule: Schedule, goal: Goal, unit: String,
                     reminderEnabled: Bool, reminderHour: Int, reminderMinute: Int) {
        habit.name = name
        habit.icon = icon
        habit.colorHex = colorHex
        habit.kindRaw = kind.rawValue
        switch schedule {
        case .daily: habit.schedTypeRaw = "daily"; habit.schedDays = []
        case .week(let days): habit.schedTypeRaw = "week"; habit.schedDays = days
        }
        switch goal {
        case .check: habit.goalTypeRaw = GoalKind.check.rawValue; habit.target = 0; habit.step = 1
        case .measure(let target, let step):
            habit.goalTypeRaw = GoalKind.measure.rawValue; habit.target = target; habit.step = step
        }
        habit.unit = unit
        habit.reminderEnabled = reminderEnabled
        habit.reminderHour = reminderHour
        habit.reminderMinute = reminderMinute
        try? context.save()
        NotificationManager.reschedule(for: habit)
        load()
    }

    func deleteHabit(_ habit: Habit) {
        NotificationManager.cancel(habitID: habit.id)
        context.delete(habit)   // cascade-deletes logs
        try? context.save()
        load()
    }

    // MARK: - Internals

    /// Idempotent per-day upsert: one row per (habit, dayKey); delete the row when value hits 0.
    private func writeLog(_ habit: Habit, dayKey key: String, dayStart day: Date, value newValue: Int) {
        var map = logIndex[habit.id] ?? [:]
        if newValue == 0 { map[key] = nil } else { map[key] = newValue }
        logIndex[habit.id] = map

        if let existing = (habit.logs ?? []).first(where: { $0.dayKey == key }) {
            if newValue == 0 {
                context.delete(existing)
            } else {
                existing.count = newValue
            }
        } else if newValue != 0 {
            context.insert(HabitLog(dayKey: key, dayStart: day, count: newValue, habit: habit))
        }
        try? context.save()
    }

    /// Recompute all cached stats from the in-memory indices. Called only after a mutation / load.
    func recompute() {
        let t = today
        let items = habits.map {
            HabitDerivations.HabitData(spec: $0.spec, logs: logIndex[$0.id] ?? [:])
        }

        var byHabit: [String: HabitStats] = [:]
        var rates: [Double] = []
        var bestAll = 0
        var totalAll = 0
        for habit in habits {
            let logs = logIndex[habit.id] ?? [:]
            let stats = HabitStats(
                streak: HabitDerivations.streak(habit.spec, logs, today: t),
                best: HabitDerivations.bestStreak(habit.spec, logs, today: t),
                rate30: HabitDerivations.rate(habit.spec, logs, days: 30, today: t),
                totalDone: HabitDerivations.totalDone(habit.spec, logs)
            )
            byHabit[habit.id] = stats
            rates.append(stats.rate30)
            bestAll = max(bestAll, stats.best)
            totalAll += stats.totalDone
        }
        statsByHabit = byHabit

        var g = GlobalStats()
        g.avgCompletion30 = rates.isEmpty ? 0 : rates.reduce(0, +) / Double(rates.count)
        g.bestStreak = bestAll
        g.totalCheckins = totalAll
        g.perfectDays30 = HabitDerivations.perfectDays(items, days: 30, today: t)
        g.xp = g.totalCheckins * 12 + g.bestStreak * 8   // monotonic-ish, no extra scan
        g.level = Level.info(forXP: g.xp).level
        g.dowRates = HabitDerivations.dowRates(items, days: 84, today: t)
        g.weeklyTrend = HabitDerivations.weeklyTrend(items, weeks: 8, today: t)
        g.aggregateHeat = HabitDerivations.heatGrid(items: items, spec: nil, logs: nil, today: t)
        global = g

        writeSnapshot()
        detectAchievements()
    }

    /// Compare currently-earned badges to the persisted "seen" set. On the very first run we adopt
    /// the current state silently (no flood of celebrations); afterwards a newly-earned badge is
    /// surfaced via `pendingAchievement` for the UI to celebrate.
    private func detectAchievements() {
        let earned = Achievements.earnedIDs(for: global)
        let defaults = AppGroup.defaults
        let key = "seenAchievements"

        guard let seenArray = defaults.stringArray(forKey: key) else {
            defaults.set(Array(earned), forKey: key)
            return
        }
        let seen = Set(seenArray)
        let newlyEarned = earned.subtracting(seen)
        guard !newlyEarned.isEmpty else {
            if earned != seen { defaults.set(Array(earned), forKey: key) }   // keep in sync
            return
        }
        defaults.set(Array(earned), forKey: key)
        pendingAchievement = Achievements.all(for: global).first { newlyEarned.contains($0.id) }
    }

    /// Publish a lightweight "today" snapshot to the shared App Group and refresh widgets.
    /// Runs after every load/mutation (via `recompute`). No-ops gracefully until the App Group
    /// container is reachable.
    private func writeSnapshot() {
        let d = today
        let items = habits
            .filter { HabitDerivations.isScheduled($0.spec, on: d) }
            .map { habit -> HabitSnapshot.Item in
                let v = value(habit, on: d)
                let done = isDone(habit, on: d)
                let progress: Double
                switch habit.goal {
                case .check: progress = done ? 1 : 0
                case .measure(let target, _): progress = target > 0 ? min(1, Double(v) / Double(target)) : 0
                }
                return HabitSnapshot.Item(id: habit.id, icon: habit.icon, name: habit.name,
                                          colorHex: habit.colorHex, done: done, progress: progress)
            }
        let snapshot = HabitSnapshot(dayKey: DayKey.key(d),
                                     doneCount: items.filter(\.done).count,
                                     total: items.count,
                                     bestStreak: global.bestStreak,
                                     items: items)
        SnapshotStore.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
