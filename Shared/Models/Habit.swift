//
//  Habit.swift
//  HabitTracker
//
//  SwiftData model for a habit. Enums are stored as raw strings for forward compatibility;
//  typed `spec` bridges to the pure derivation layer.
//

import Foundation
import SwiftData

@Model
final class Habit {
    // Not `.unique`: CloudKit-backed SwiftData forbids unique constraints. Uniqueness is upheld
    // by the store's id-keyed upserts instead.
    var id: String = UUID().uuidString
    var name: String = ""
    var icon: String = "⭐"
    var colorHex: String = "#FF6B5E"
    var category: String = "Custom"
    var kindRaw: String = HabitKind.build.rawValue
    var schedTypeRaw: String = "daily"     // "daily" | "week"
    var schedDays: [Int] = []              // 0 = Sun ... 6 = Sat (empty when daily)
    var goalTypeRaw: String = GoalKind.check.rawValue
    var target: Int = 0
    var unit: String = ""
    var step: Int = 1
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    // Reminder (local notification). Hour/minute are local time-of-day; -1 hour means unset.
    var reminderEnabled: Bool = false
    var reminderHour: Int = 9
    var reminderMinute: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog]? = []

    init(id: String = UUID().uuidString,
         name: String,
         icon: String,
         colorHex: String,
         category: String = "Custom",
         kind: HabitKind,
         schedule: Schedule,
         goal: Goal,
         unit: String = "",
         sortOrder: Int = 0,
         createdAt: Date = Date(),
         reminderEnabled: Bool = false,
         reminderHour: Int = 9,
         reminderMinute: Int = 0) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.category = category
        self.kindRaw = kind.rawValue
        switch schedule {
        case .daily:
            self.schedTypeRaw = "daily"
            self.schedDays = []
        case .week(let days):
            self.schedTypeRaw = "week"
            self.schedDays = days
        }
        switch goal {
        case .check:
            self.goalTypeRaw = GoalKind.check.rawValue
            self.target = 0
            self.step = 1
        case .measure(let target, let step):
            self.goalTypeRaw = GoalKind.measure.rawValue
            self.target = target
            self.step = step
        }
        self.unit = unit
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }

    var kind: HabitKind { HabitKind(rawValue: kindRaw) ?? .build }

    var schedule: Schedule {
        schedTypeRaw == "week" ? .week(schedDays) : .daily
    }

    var goal: Goal {
        goalTypeRaw == GoalKind.measure.rawValue ? .measure(target: target, step: step) : .check
    }

    var spec: HabitSpec {
        HabitSpec(id: id, kind: kind, schedule: schedule, goal: goal)
    }
}
