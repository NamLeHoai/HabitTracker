//
//  GamificationTests.swift
//  HabitTrackerTests
//
//  Pure tests for the XP→level curve and badge-unlock thresholds.
//

import Testing
@testable import HabitTracker

struct GamificationTests {
    @Test func levelStartsAtOne() {
        let info = Level.info(forXP: 0)
        #expect(info.level == 1)
        #expect(info.xpIntoLevel == 0)
        #expect(info.progress == 0)
    }

    @Test func levelAdvancesEveryTier() {
        #expect(Level.info(forXP: 249).level == 1)
        #expect(Level.info(forXP: 250).level == 2)
        #expect(Level.info(forXP: 500).level == 3)
        #expect(Level.info(forXP: 251).xpIntoLevel == 1)
    }

    @Test func levelClampsNegativeXP() {
        #expect(Level.info(forXP: -100).level == 1)
    }

    @Test func noBadgesWithNoProgress() {
        #expect(Achievements.earnedIDs(for: .empty).isEmpty)
    }

    @Test func streakBadgesUnlockAtThresholds() {
        var g = GlobalStats.empty
        g.bestStreak = 7
        let earned = Achievements.earnedIDs(for: g)
        #expect(earned.contains("streak7"))
        #expect(!earned.contains("streak30"))
    }

    @Test func checkinBadgeUnlocks() {
        var g = GlobalStats.empty
        g.totalCheckins = 10
        #expect(Achievements.earnedIDs(for: g).contains("checkins10"))
    }

    @Test func levelBadgeReflectsXP() {
        var g = GlobalStats.empty
        g.xp = Level.xpPerLevel * 4   // -> level 5
        #expect(Achievements.earnedIDs(for: g).contains("level5"))
        #expect(!Achievements.earnedIDs(for: g).contains("level10"))
    }
}
