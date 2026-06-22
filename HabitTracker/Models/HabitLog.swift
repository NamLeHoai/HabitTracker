//
//  HabitLog.swift
//  HabitTracker
//
//  One row per (habit, day). `dayKey` is the canonical bucket; idempotent upsert in
//  HabitStore guarantees at most one row per habit per day.
//

import Foundation
import SwiftData

@Model
final class HabitLog {
    var dayKey: String = ""      // "YYYY-MM-DD"
    var dayStart: Date = Date()  // local midnight, for sorting / display
    var count: Int = 0           // check: 0/1; measure: accumulated count
    var habit: Habit?

    init(dayKey: String, dayStart: Date, count: Int, habit: Habit? = nil) {
        self.dayKey = dayKey
        self.dayStart = dayStart
        self.count = count
        self.habit = habit
    }
}
