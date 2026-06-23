//
//  HabitStats.swift
//  HabitTracker
//
//  Cached derived values. Computed once per data mutation by `HabitStore.recompute()`
//  and read by views — never recomputed inside a SwiftUI `body`.
//

import Foundation

struct HabitStats: Equatable {
    var streak: Int = 0
    var best: Int = 0
    var rate30: Double = 0
    var totalDone: Int = 0
}

struct GlobalStats: Equatable {
    var avgCompletion30: Double = 0          // mean of per-habit 30-day rate
    var bestStreak: Int = 0                  // max best streak across habits
    var totalCheckins: Int = 0               // Σ totalDone
    var perfectDays30: Int = 0
    var xp: Int = 0                          // lifetime XP from completions + streak bonus
    var level: Int = 1                       // derived from xp via Level
    var dowRates: [Double] = Array(repeating: 0, count: 7)   // 0 = Sun ... 6 = Sat
    var weeklyTrend: [Double] = Array(repeating: 0, count: 8) // oldest first
    var aggregateHeat: [[Int]] = []          // 18 columns × 7 rows

    static let empty = GlobalStats()
}
