//
//  Achievements.swift
//  HabitTracker (Shared)
//
//  Pure badge definitions evaluated against the cached GlobalStats. `all(for:)` returns every
//  badge with its earned/locked state for display; `earnedIDs(for:)` is used by the store to
//  detect newly-unlocked badges and trigger a celebration.
//

import Foundation

struct Achievement: Identifiable, Equatable {
    let id: String
    let icon: String
    let title: String
    let detail: String
    let isEarned: Bool
}

enum Achievements {
    /// Ordered list of every badge with its current earned state.
    static func all(for g: GlobalStats) -> [Achievement] {
        let level = Level.info(forXP: g.xp).level
        return [
            make("checkins10",  "🌱", "Getting Started", "Log 10 check-ins",      g.totalCheckins >= 10),
            make("streak7",     "🔥", "On Fire",         "Reach a 7-day streak",  g.bestStreak >= 7),
            make("perfect1",    "⭐️", "Perfect Day",      "Complete a perfect day", g.perfectDays30 >= 1),
            make("level5",      "🚀", "Rising Star",      "Reach level 5",         level >= 5),
            make("checkins100", "🏆", "Dedicated",        "Log 100 check-ins",     g.totalCheckins >= 100),
            make("streak30",    "⚡️", "Unstoppable",      "Reach a 30-day streak", g.bestStreak >= 30),
            make("perfect7",    "🌟", "Perfect Week",     "7 perfect days",        g.perfectDays30 >= 7),
            make("level10",     "👑", "Habit Master",     "Reach level 10",        level >= 10),
            make("streak100",   "💯", "Centurion",        "Reach a 100-day streak", g.bestStreak >= 100),
        ]
    }

    static func earnedIDs(for g: GlobalStats) -> Set<String> {
        Set(all(for: g).filter(\.isEarned).map(\.id))
    }

    private static func make(_ id: String, _ icon: String, _ title: String,
                             _ detail: String, _ earned: Bool) -> Achievement {
        Achievement(id: id, icon: icon, title: title, detail: detail, isEarned: earned)
    }
}
