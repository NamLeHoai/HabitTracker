//
//  SharedStore.swift
//  HabitTracker (Shared)
//
//  The single SwiftData schema + App Group-backed container, used by both the app and the
//  widget extension so they read and write the same on-disk store.
//

import Foundation
import SwiftData

enum SharedStore {
    static let schema = Schema([Habit.self, HabitLog.self, MoodEntry.self])
    static let cloudContainerID = "iCloud.com.namle.HabitTracker"

    /// Gated off by default. The Settings toggle flips it; takes effect on next launch (the
    /// container is built once at startup). Requires the iCloud capability + a provisioned
    /// CloudKit container, so it stays off until the user opts in.
    static var isCloudEnabled: Bool { AppGroup.defaults.bool(forKey: "iCloudSyncEnabled") }

    static func container() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(AppGroup.id),
            cloudKitDatabase: isCloudEnabled ? .private(cloudContainerID) : .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
