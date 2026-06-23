//
//  HabitSnapshot.swift
//  HabitTracker
//
//  A lightweight, Codable view of "today" that the app writes to the shared App Group container
//  on every recompute, and that the widget reads for fast, allocation-free rendering. This file
//  lives in the Shared module so both the app and the widget extension compile the same types.
//

import Foundation

struct HabitSnapshot: Codable {
    struct Item: Codable, Identifiable {
        var id: String
        var icon: String
        var name: String
        var colorHex: String
        var done: Bool
        var progress: Double   // 0...1
    }

    var dayKey: String
    var doneCount: Int
    var total: Int
    var bestStreak: Int
    var items: [Item]

    static let empty = HabitSnapshot(dayKey: "", doneCount: 0, total: 0, bestStreak: 0, items: [])

    /// Placeholder used by the widget gallery / previews.
    static let sample = HabitSnapshot(
        dayKey: "", doneCount: 3, total: 5, bestStreak: 12,
        items: [
            .init(id: "1", icon: "💧", name: "Drink Water", colorHex: "#3B9EFF", done: true, progress: 1),
            .init(id: "2", icon: "🏃", name: "Morning Run", colorHex: "#FF6B5E", done: true, progress: 1),
            .init(id: "3", icon: "📖", name: "Read", colorHex: "#FFB23E", done: true, progress: 1),
            .init(id: "4", icon: "🧘", name: "Meditate", colorHex: "#7B79FF", done: false, progress: 0),
            .init(id: "5", icon: "💊", name: "Vitamins", colorHex: "#34C77B", done: false, progress: 0),
        ])

    var fraction: Double { total > 0 ? Double(doneCount) / Double(total) : 0 }
}

enum SnapshotStore {
    private static let filename = "today-snapshot.json"

    private static func url() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.id)?
            .appendingPathComponent(filename)
    }

    /// Writer (app side). No-ops if the App Group container isn't reachable yet.
    static func write(_ snapshot: HabitSnapshot) {
        guard let url = url(), let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// Reader (used by the app for previews / the widget has its own copy).
    static func read() -> HabitSnapshot {
        guard let url = url(),
              let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(HabitSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }
}
