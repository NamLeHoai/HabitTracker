//
//  AppGroup.swift
//  HabitTracker
//
//  Shared App Group identity. The app and the widget extension both read/write the SwiftData
//  store and the today-snapshot through this group container, so they must use the same id.
//

import Foundation

enum AppGroup {
    static let id = "group.com.namle.HabitTracker"

    /// App-group-scoped defaults. Falls back to `.standard` if the entitlement isn't present yet
    /// (e.g. before the capability is wired), so callers never crash.
    static var defaults: UserDefaults { UserDefaults(suiteName: id) ?? .standard }
}
