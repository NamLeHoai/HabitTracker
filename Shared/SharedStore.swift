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

    /// Master kill-switch. While `true`, iCloud sync is fully off (container is local) regardless
    /// of the user flag, and the Settings sync section is hidden. To re-enable: flip to `false`,
    /// re-add the iCloud/CloudKit keys to both .entitlements, and provision the CloudKit container.
    static let cloudKitTemporarilyDisabled = true

    /// Gated off by default. The Settings toggle flips the flag; takes effect on next launch.
    static var isCloudEnabled: Bool {
        guard !cloudKitTemporarilyDisabled else { return false }
        return AppGroup.defaults.bool(forKey: "iCloudSyncEnabled")
    }

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
