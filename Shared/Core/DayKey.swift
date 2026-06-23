//
//  DayKey.swift
//  HabitTracker
//
//  Day bucketing helpers. Everything is keyed by a local "YYYY-MM-DD" string
//  (mirrors the prototype's `key(d)`) so day math is deterministic and DST-safe.
//

import Foundation

enum DayKey {
    /// Gregorian calendar in the current timezone. Shared so keys and weekday math agree everywhere.
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .current
        return c
    }()

    /// Local "YYYY-MM-DD" for the given date.
    static func key(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func addDays(_ date: Date, _ n: Int) -> Date {
        calendar.date(byAdding: .day, value: n, to: date) ?? date
    }

    /// 0 = Sunday ... 6 = Saturday (JS `getDay()` parity; Foundation returns 1...7).
    static func weekdayIndex(_ date: Date) -> Int {
        calendar.component(.weekday, from: date) - 1
    }
}
