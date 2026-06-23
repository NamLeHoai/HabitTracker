//
//  HabitSnapshot.swift
//  HabitTracker
//
//  A lightweight, Codable view of "today" that the app writes to the shared App Group container
//  on every recompute. The widget reads this snapshot instead of compiling the whole SwiftData /
//  derivation stack — keeping the widget extension small and the data access cheap.
//
//  The widget target has its own identical copy of these types (it only decodes), so the two
//  targets stay self-contained. Keep the Codable shape in sync across both copies.
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
