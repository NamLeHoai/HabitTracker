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
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let created: ModelContainer
        do {
            created = try SharedStore.container()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        container = created
        _store = State(initialValue: HabitStore(context: created.mainContext))
    }

    /// True when hosted by the XCTest runner. Unit tests drive their own in-memory stores, so the
    /// app must stay quiescent — otherwise its SwiftUI/SwiftData work races the tests' model access.
    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    var body: some Scene {
        WindowGroup {
            if isRunningTests {
                Color.clear
            } else {
                RootView()
                    .environment(store)
                    .environment(theme)
                    .preferredColorScheme(theme.isDark ? .dark : .light)
                    .task { store.loadAndSeedIfNeeded() }
                    .onChange(of: scenePhase) { _, phase in
                        // Pick up changes made from the widget (interactive toggles) on foreground.
                        if phase == .active { store.load() }
                    }
            }
        }
        .modelContainer(container)
    }
}
