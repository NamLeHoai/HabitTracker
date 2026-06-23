//
//  NotificationManager.swift
//  HabitTracker
//
//  Local reminder scheduling. One repeating UNCalendarNotificationTrigger per habit for daily
//  schedules, or one per selected weekday for weekly schedules. Identifiers are derived from the
//  habit id so a reschedule/cancel is idempotent. Called by HabitStore on create/update/delete.
//

import Foundation
import UserNotifications

enum NotificationManager {
    /// Prompts on first call; thereafter returns the existing status without re-prompting.
    @discardableResult
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Remove any pending reminders for a habit, then (if enabled and authorized) schedule fresh ones.
    static func reschedule(for habit: Habit) {
        let id = habit.id
        let enabled = habit.reminderEnabled
        let icon = habit.icon
        let name = habit.name
        let isQuit = habit.kind == .quit
        let hour = habit.reminderHour
        let minute = habit.reminderMinute
        let schedule = habit.schedule

        cancel(habitID: id)
        guard enabled else { return }

        Task {
            guard await requestAuthorization() else { return }
            let center = UNUserNotificationCenter.current()

            let content = UNMutableNotificationContent()
            content.title = "\(icon) \(name)".trimmingCharacters(in: .whitespaces)
            content.body = isQuit ? "Stay strong — keep your streak alive." : "Time to check in."
            content.sound = .default

            var base = DateComponents()
            base.hour = hour
            base.minute = minute

            switch schedule {
            case .daily:
                let trigger = UNCalendarNotificationTrigger(dateMatching: base, repeats: true)
                try? await center.add(UNNotificationRequest(identifier: identifier(id), content: content, trigger: trigger))
            case .week(let days):
                for day in days {
                    var comps = base
                    comps.weekday = day + 1   // our index 0=Sun…6=Sat → DateComponents 1=Sun…7=Sat
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                    try? await center.add(UNNotificationRequest(identifier: identifier(id, day), content: content, trigger: trigger))
                }
            }
        }
    }

    static func cancel(habitID: String) {
        let ids = [identifier(habitID)] + (0..<7).map { identifier(habitID, $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func identifier(_ habitID: String, _ weekday: Int? = nil) -> String {
        weekday.map { "habit-\(habitID)-\($0)" } ?? "habit-\(habitID)"
    }
}
