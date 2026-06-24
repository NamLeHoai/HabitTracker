//
//  BackupData.swift
//  HabitTracker
//
//  Codable snapshot of the entire store for JSON export / import. DTOs mirror the @Model fields
//  by raw value so a backup is portable and version-tolerant.
//

import Foundation

struct BackupData: Codable {
    struct HabitDTO: Codable {
        var id: String
        var name: String
        var icon: String
        var colorHex: String
        var category: String
        var kindRaw: String
        var schedTypeRaw: String
        var schedDays: [Int]
        var goalTypeRaw: String
        var target: Int
        var unit: String
        var step: Int
        var sortOrder: Int
        var createdAt: Date
        var reminderEnabled: Bool
        var reminderHour: Int
        var reminderMinute: Int
    }

    struct LogDTO: Codable {
        var habitID: String
        var dayKey: String
        var dayStart: Date
        var count: Int
    }

    struct MoodDTO: Codable {
        var dayKey: String
        var dayStart: Date
        var value: Int
    }

    var version: Int = 1
    var exportedAt: Date
    var habits: [HabitDTO]
    var logs: [LogDTO]
    var moods: [MoodDTO]
}

extension BackupData.HabitDTO {
    var schedule: Schedule { schedTypeRaw == "week" ? .week(schedDays) : .daily }
    var goal: Goal { goalTypeRaw == GoalKind.measure.rawValue ? .measure(target: target, step: step) : .check }
    var kind: HabitKind { HabitKind(rawValue: kindRaw) ?? .build }
}
