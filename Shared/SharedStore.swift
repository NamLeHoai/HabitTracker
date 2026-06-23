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

    static func container() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false,
                                               groupContainer: .identifier(AppGroup.id))
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
