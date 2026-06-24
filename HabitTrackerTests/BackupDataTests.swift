//
//  BackupDataTests.swift
//  HabitTrackerTests
//
//  Pure JSON round-trip for the backup format (no SwiftData).
//

import Testing
import Foundation
@testable import HabitTracker

struct BackupDataTests {
    @Test func backupRoundTripsThroughJSON() throws {
        let backup = BackupData(
            exportedAt: Date(timeIntervalSince1970: 1_700_000_000),
            habits: [.init(id: "h1", name: "Water", icon: "💧", colorHex: "#3B9EFF", category: "Health",
                           kindRaw: "build", schedTypeRaw: "week", schedDays: [1, 3, 5], goalTypeRaw: "measure",
                           target: 8, unit: "glasses", step: 1, sortOrder: 0,
                           createdAt: Date(timeIntervalSince1970: 1),
                           reminderEnabled: true, reminderHour: 9, reminderMinute: 30)],
            logs: [.init(habitID: "h1", dayKey: "2026-06-24", dayStart: Date(timeIntervalSince1970: 2), count: 3)],
            moods: [.init(dayKey: "2026-06-24", dayStart: Date(timeIntervalSince1970: 2), value: 4)])

        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let restored = try decoder.decode(BackupData.self, from: data)

        #expect(restored.version == 1)
        #expect(restored.habits.count == 1)
        #expect(restored.habits[0].schedDays == [1, 3, 5])
        #expect(restored.habits[0].target == 8)
        #expect(restored.habits[0].reminderHour == 9)
        #expect(restored.logs[0].count == 3)
        #expect(restored.moods[0].value == 4)
    }

    @Test func dtoReconstructsScheduleAndGoal() {
        let measureWeek = BackupData.HabitDTO(
            id: "x", name: "", icon: "", colorHex: "", category: "", kindRaw: "build",
            schedTypeRaw: "week", schedDays: [0, 6], goalTypeRaw: "measure", target: 5, unit: "",
            step: 1, sortOrder: 0, createdAt: .init(timeIntervalSince1970: 0),
            reminderEnabled: false, reminderHour: 9, reminderMinute: 0)
        if case .week(let days) = measureWeek.schedule { #expect(days == [0, 6]) } else { Issue.record("expected week") }
        if case .measure(let target, _) = measureWeek.goal { #expect(target == 5) } else { Issue.record("expected measure") }
    }
}
