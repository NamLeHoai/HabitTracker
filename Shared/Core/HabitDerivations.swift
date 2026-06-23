//
//  HabitDerivations.swift
//  HabitTracker
//
//  Pure, side-effect-free derivation functions ported verbatim from the prototype's
//  `Component` class (Habit Tracker.dc.html, ~lines 626–831). No SwiftData / SwiftUI imports.
//
//  Performance contract: these scan up to ~400 days, so they MUST NOT be called from a
//  SwiftUI `body`. `HabitStore` calls them once per data mutation and caches the results.
//  Every function takes an explicit `today` for determinism (the prototype hard-codes it).
//

import Foundation

enum HabitDerivations {
    /// dayKey ("YYYY-MM-DD") -> count. check habits store 0/1; measure habits store the accumulated count.
    typealias Logs = [String: Int]

    /// A habit paired with its logs, for aggregate (cross-habit) calculations.
    struct HabitData {
        let spec: HabitSpec
        let logs: Logs
    }

    // MARK: - Primitives

    static func isScheduled(_ spec: HabitSpec, on date: Date) -> Bool {
        switch spec.schedule {
        case .daily:
            return true
        case .week(let days):
            return days.contains(DayKey.weekdayIndex(date))
        }
    }

    static func value(_ logs: Logs, on date: Date) -> Int {
        logs[DayKey.key(date)] ?? 0
    }

    static func isDone(_ spec: HabitSpec, value v: Int) -> Bool {
        switch spec.goal {
        case .check:
            return v >= 1
        case .measure(let target, _):
            return v >= target
        }
    }

    static func isDone(_ spec: HabitSpec, _ logs: Logs, on date: Date) -> Bool {
        isDone(spec, value: value(logs, on: date))
    }

    // MARK: - Per-habit stats

    /// Walks back over scheduled days. Today-not-done does NOT break the streak (it's skipped);
    /// any earlier scheduled miss breaks it. (prototype line 626)
    static func streak(_ spec: HabitSpec, _ logs: Logs, today: Date) -> Int {
        var c = 0
        for off in 0..<400 {
            let d = DayKey.addDays(today, -off)
            if !isScheduled(spec, on: d) { continue }
            if isDone(spec, logs, on: d) {
                c += 1
            } else if off == 0 {
                continue
            } else {
                break
            }
        }
        return c
    }

    /// Longest run of completed scheduled days, never less than the current streak. (prototype line 627)
    static func bestStreak(_ spec: HabitSpec, _ logs: Logs, today: Date) -> Int {
        var best = 0
        var run = 0
        var off = 400
        while off >= 0 {
            let d = DayKey.addDays(today, -off)
            if isScheduled(spec, on: d) {
                if isDone(spec, logs, on: d) {
                    run += 1
                    if run > best { best = run }
                } else if off == 0 {
                    // today not done: don't reset (mirrors prototype no-op)
                } else {
                    run = 0
                }
            }
            off -= 1
        }
        return max(best, streak(spec, logs, today: today))
    }

    /// Completion ratio over the last `days` scheduled days, EXCLUDING today. (prototype line 628)
    static func rate(_ spec: HabitSpec, _ logs: Logs, days: Int, today: Date) -> Double {
        guard days >= 1 else { return 0 }
        var scheduled = 0
        var done = 0
        for off in 1...days {
            let d = DayKey.addDays(today, -off)
            if !isScheduled(spec, on: d) { continue }
            scheduled += 1
            if isDone(spec, logs, on: d) { done += 1 }
        }
        return scheduled != 0 ? Double(done) / Double(scheduled) : 0
    }

    /// Count of logged days that satisfy completion. (prototype line 629)
    static func totalDone(_ spec: HabitSpec, _ logs: Logs) -> Int {
        var c = 0
        for (_, v) in logs where isDone(spec, value: v) { c += 1 }
        return c
    }

    /// New "today" value when toggled. (prototype line 632)
    static func toggledValue(_ spec: HabitSpec, current cur: Int) -> Int {
        switch spec.goal {
        case .check:
            return cur >= 1 ? 0 : 1
        case .measure(let target, let step):
            return cur >= target ? 0 : min(target, cur + step)
        }
    }

    // MARK: - Heatmap

    /// Per-habit level: future -1 (blank), unscheduled 0, done 4, partial 2, missed 1. (prototype line 774)
    static func heatLevel(_ spec: HabitSpec, _ logs: Logs, on date: Date, today: Date) -> Int {
        if DayKey.startOfDay(date) > DayKey.startOfDay(today) { return -1 }
        if !isScheduled(spec, on: date) { return 0 }
        if isDone(spec, logs, on: date) { return 4 }
        if value(logs, on: date) > 0 { return 2 }
        return 1
    }

    /// Aggregate level across all habits. NOTE the floor of 1 for any scheduled day. (prototype line 775)
    static func aggregateHeatLevel(_ items: [HabitData], on date: Date, today: Date) -> Int {
        if DayKey.startOfDay(date) > DayKey.startOfDay(today) { return -1 }
        let scheduled = items.filter { isScheduled($0.spec, on: date) }
        if scheduled.isEmpty { return 0 }
        let done = scheduled.filter { isDone($0.spec, $0.logs, on: date) }.count
        let fr = Double(done) / Double(scheduled.count)
        if fr == 0 { return 1 }
        return max(1, Int(ceil(fr * 4)))
    }

    /// 18 columns × 7 rows of levels, aligned to the nearest Sunday 17 weeks back. (prototype line 765)
    /// Pass `spec`+`logs` for a single habit, or `items` (with spec/logs nil) for the aggregate grid.
    static func heatGrid(items: [HabitData], spec: HabitSpec?, logs: Logs?, today: Date) -> [[Int]] {
        var start = DayKey.addDays(today, -7 * 17)
        while DayKey.weekdayIndex(start) != 0 { start = DayKey.addDays(start, -1) }
        var weeks: [[Int]] = []
        var cur = start
        for _ in 0..<18 {
            var column: [Int] = []
            for _ in 0..<7 {
                let level: Int
                if let spec {
                    level = heatLevel(spec, logs ?? [:], on: cur, today: today)
                } else {
                    level = aggregateHeatLevel(items, on: cur, today: today)
                }
                column.append(level)
                cur = DayKey.addDays(cur, 1)
            }
            weeks.append(column)
        }
        return weeks
    }

    // MARK: - Aggregate stats

    /// Days in the last `days` where every scheduled habit was completed. (prototype line 806)
    static func perfectDays(_ items: [HabitData], days: Int, today: Date) -> Int {
        guard days >= 1 else { return 0 }
        var perfect = 0
        for off in 1...days {
            let d = DayKey.addDays(today, -off)
            let scheduled = items.filter { isScheduled($0.spec, on: d) }
            if !scheduled.isEmpty && scheduled.allSatisfy({ isDone($0.spec, $0.logs, on: d) }) {
                perfect += 1
            }
        }
        return perfect
    }

    /// Completion ratio per weekday (index 0 = Sun ... 6 = Sat) over `days`. (prototype line 808)
    static func dowRates(_ items: [HabitData], days: Int, today: Date) -> [Double] {
        guard days >= 1 else { return Array(repeating: 0, count: 7) }
        var scheduled = Array(repeating: 0, count: 7)
        var done = Array(repeating: 0, count: 7)
        for off in 1...days {
            let d = DayKey.addDays(today, -off)
            let k = DayKey.weekdayIndex(d)
            let sc = items.filter { isScheduled($0.spec, on: d) }
            scheduled[k] += sc.count
            done[k] += sc.filter { isDone($0.spec, $0.logs, on: d) }.count
        }
        return (0..<7).map { scheduled[$0] != 0 ? Double(done[$0]) / Double(scheduled[$0]) : 0 }
    }

    /// Weekly completion ratios, oldest first (default 8 weeks). (prototype line 811)
    static func weeklyTrend(_ items: [HabitData], weeks: Int = 8, today: Date) -> [Double] {
        guard weeks >= 1 else { return [] }
        var out: [Double] = []
        for w in stride(from: weeks - 1, through: 0, by: -1) {
            var scheduled = 0
            var done = 0
            for i in 0..<7 {
                let d = DayKey.addDays(today, -(w * 7 + i))
                let sc = items.filter { isScheduled($0.spec, on: d) }
                scheduled += sc.count
                done += sc.filter { isDone($0.spec, $0.logs, on: d) }.count
            }
            out.append(scheduled != 0 ? Double(done) / Double(scheduled) : 0)
        }
        return out
    }
}
