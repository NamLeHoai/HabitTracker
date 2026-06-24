//
//  MoodEntry.swift
//  HabitTracker
//
//  One mood (1...5) per day. `dayKey` is unique so writes upsert cleanly.
//

import Foundation
import SwiftData

@Model
final class MoodEntry {
    var dayKey: String = ""   // "YYYY-MM-DD" — uniqueness upheld by the store's per-day upsert
                              // (not `.unique`: CloudKit-backed SwiftData forbids unique constraints)
    var dayStart: Date = Date()
    var value: Int = 0                             // 1...5

    init(dayKey: String, dayStart: Date, value: Int) {
        self.dayKey = dayKey
        self.dayStart = dayStart
        self.value = value
    }
}
