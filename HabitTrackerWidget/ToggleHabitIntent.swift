//
//  ToggleHabitIntent.swift
//  HabitTrackerWidget
//
//  Interactive widget action: toggle a habit's completion for today directly from the widget,
//  without launching the app. Writes to the shared SwiftData store, republishes the snapshot,
//  and reloads timelines so the widget reflects the change immediately.
//

import AppIntents
import WidgetKit
import SwiftData

struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit"
    static var isDiscoverable: Bool = false   // internal action, not a Shortcuts suggestion

    @Parameter(title: "Habit") var habitID: String

    init() {}
    init(habitID: String) { self.habitID = habitID }

    @MainActor
    func perform() async throws -> some IntentResult {
        if let container = try? SharedStore.container() {
            let context = container.mainContext
            HabitMutations.toggleToday(habitID: habitID, in: context)
            SnapshotStore.write(HabitMutations.buildSnapshot(from: context))
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
