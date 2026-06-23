//
//  Level.swift
//  HabitTracker (Shared)
//
//  Pure XP → level mapping. XP is derived from real completions (see HabitStore.recompute), and
//  levels are a flat curve so the progress bar is easy to read. Titles give each tier some flavor.
//

import Foundation

struct LevelInfo: Equatable {
    let level: Int
    let title: String
    let xp: Int
    let xpIntoLevel: Int
    let xpForLevel: Int

    var progress: Double { xpForLevel > 0 ? Double(xpIntoLevel) / Double(xpForLevel) : 0 }
    var xpToNext: Int { max(0, xpForLevel - xpIntoLevel) }
}

enum Level {
    static let xpPerLevel = 250

    static func info(forXP xp: Int) -> LevelInfo {
        let clamped = max(0, xp)
        let level = clamped / xpPerLevel + 1
        let into = clamped % xpPerLevel
        return LevelInfo(level: level, title: title(for: level), xp: clamped,
                         xpIntoLevel: into, xpForLevel: xpPerLevel)
    }

    static func title(for level: Int) -> String {
        switch level {
        case ..<2: return "Beginner"
        case 2..<3: return "Starter"
        case 3..<5: return "Builder"
        case 5..<8: return "Achiever"
        case 8..<12: return "Champion"
        case 12..<20: return "Master"
        default: return "Legend"
        }
    }
}
