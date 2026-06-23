//
//  HabitTrackerApp.swift
//  HabitTracker
//
//  Created by Nam Le on 21/6/26.
//

import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {
    let container: ModelContainer
    @State private var store: HabitStore
    @State private var theme = ThemeManager()

    init() {
        let schema = Schema([Habit.self, HabitLog.self, MoodEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false,
                                               groupContainer: .identifier(AppGroup.id))
        let created: ModelContainer
        do {
            created = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        container = created
        _store = State(initialValue: HabitStore(context: created.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(theme)
                .preferredColorScheme(theme.isDark ? .dark : .light)
                .task { store.loadAndSeedIfNeeded() }
        }
        .modelContainer(container)
    }
}
