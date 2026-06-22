//
//  HabitDerivationsTests.swift
//  HabitTrackerTests
//
//  Tests for the pure derivation layer (the highest-risk logic). All use a fixed
//  reference "today" and in-memory log dictionaries — no SwiftData, fully deterministic.
//

import Testing
import Foundation
@testable import HabitTracker

private let cal = DayKey.calendar

/// Fixed reference date: Sunday, June 21, 2026 (mirrors the prototype's hard-coded today).
private let refToday: Date = {
    var c = DateComponents()
    c.year = 2026; c.month = 6; c.day = 21
    return cal.date(from: c)!
}()

/// Build a logs dict from "days ago" offsets → count.
private func logs(_ entries: [Int: Int], from today: Date = refToday) -> HabitDerivations.Logs {
    var out: HabitDerivations.Logs = [:]
    for (off, count) in entries {
        out[DayKey.key(DayKey.addDays(today, -off))] = count
    }
    return out
}

private func checkHabit(_ schedule: Schedule = .daily) -> HabitSpec {
    HabitSpec(id: "c", kind: .build, schedule: schedule, goal: .check)
}
private func measureHabit(target: Int, step: Int, _ schedule: Schedule = .daily) -> HabitSpec {
    HabitSpec(id: "m", kind: .build, schedule: schedule, goal: .measure(target: target, step: step))
}

// MARK: - done / value

@Test func checkHabitIsDoneWhenValueAtLeastOne() {
    let h = checkHabit()
    #expect(HabitDerivations.isDone(h, value: 0) == false)
    #expect(HabitDerivations.isDone(h, value: 1) == true)
}

@Test func measureHabitIsDoneOnlyAtTarget() {
    let h = measureHabit(target: 8, step: 1)
    #expect(HabitDerivations.isDone(h, value: 0) == false)
    #expect(HabitDerivations.isDone(h, value: 7) == false)   // partial is NOT done
    #expect(HabitDerivations.isDone(h, value: 8) == true)
    #expect(HabitDerivations.isDone(h, value: 9) == true)
}

// MARK: - toggle

@Test func toggleCheckFlipsBetweenZeroAndOne() {
    let h = checkHabit()
    #expect(HabitDerivations.toggledValue(h, current: 0) == 1)
    #expect(HabitDerivations.toggledValue(h, current: 1) == 0)
}

@Test func toggleMeasureIncrementsByStepThenWrapsAtTarget() {
    let h = measureHabit(target: 8, step: 3)
    #expect(HabitDerivations.toggledValue(h, current: 0) == 3)
    #expect(HabitDerivations.toggledValue(h, current: 3) == 6)
    #expect(HabitDerivations.toggledValue(h, current: 6) == 8)   // capped at target, not 9
    #expect(HabitDerivations.toggledValue(h, current: 8) == 0)   // wraps to 0 at/above target
}

// MARK: - streak

@Test func streakCountsConsecutiveScheduledDoneDays() {
    let h = checkHabit()
    let l = logs([0: 1, 1: 1, 2: 1, 3: 1])
    #expect(HabitDerivations.streak(h, l, today: refToday) == 4)
}

@Test func streakTodayNotDoneDoesNotBreakIt() {
    let h = checkHabit()
    // today (offset 0) missing, but yesterday and before are done
    let l = logs([1: 1, 2: 1, 3: 1])
    #expect(HabitDerivations.streak(h, l, today: refToday) == 3)
}

@Test func streakEarlierMissBreaksIt() {
    let h = checkHabit()
    // done today + yesterday, gap two days ago, then more done
    let l = logs([0: 1, 1: 1, 3: 1, 4: 1])
    #expect(HabitDerivations.streak(h, l, today: refToday) == 2)
}

@Test func streakEmptyHistoryIsZero() {
    #expect(HabitDerivations.streak(checkHabit(), [:], today: refToday) == 0)
}

@Test func streakWeekdayOnlyHabitSkipsOffDays() {
    // Mon/Wed/Fri habit. refToday is Sunday (not scheduled) so it's skipped, not a break.
    let h = checkHabit(.week([1, 3, 5]))
    // Most recent scheduled days before Sunday 6/21: Fri 6/19 (off 2), Wed 6/17 (off 4), Mon 6/15 (off 6)
    let l = logs([2: 1, 4: 1, 6: 1])
    #expect(HabitDerivations.streak(h, l, today: refToday) == 3)
}

// MARK: - best streak

@Test func bestStreakIsAtLeastCurrentStreak() {
    let h = checkHabit()
    let l = logs([0: 1, 1: 1, 2: 1])
    #expect(HabitDerivations.bestStreak(h, l, today: refToday) >= 3)
}

@Test func bestStreakFindsLongestRun() {
    let h = checkHabit()
    // recent run of 2 (today, yesterday); older run of 4 (offsets 5..8)
    let l = logs([0: 1, 1: 1, 5: 1, 6: 1, 7: 1, 8: 1])
    #expect(HabitDerivations.bestStreak(h, l, today: refToday) == 4)
}

// MARK: - rate

@Test func rateExcludesTodayAndDividesByScheduledDays() {
    let h = checkHabit()
    // last 4 days excluding today: offsets 1..4; done on 1 and 3 → 2/4 = 0.5
    let l = logs([0: 1, 1: 1, 3: 1])
    #expect(HabitDerivations.rate(h, l, days: 4, today: refToday) == 0.5)
}

@Test func rateIsZeroWhenNoScheduledDays() {
    // Saturday-only habit, window of 1 day back (Sat 6/20 IS scheduled) → adjust to a non-scheduled window
    let h = checkHabit(.week([0]))   // Sunday-only; offsets 1..6 contain no Sunday
    #expect(HabitDerivations.rate(h, [:], days: 6, today: refToday) == 0)
}

// MARK: - totalDone

@Test func totalDoneCountsCompletedLoggedDays() {
    let h = measureHabit(target: 8, step: 1)
    // three days: 8 (done), 4 (partial, not done), 8 (done)
    let l = logs([1: 8, 2: 4, 3: 8])
    #expect(HabitDerivations.totalDone(h, l) == 2)
}

// MARK: - aggregate heat level

@Test func aggregateHeatFloorIsOneForAnyScheduledDay() {
    // one scheduled habit, not done that day → fr == 0 → level 1 (NOT 0)
    let h = checkHabit()
    let items = [HabitDerivations.HabitData(spec: h, logs: [:])]
    let yesterday = DayKey.addDays(refToday, -1)
    #expect(HabitDerivations.aggregateHeatLevel(items, on: yesterday, today: refToday) == 1)
}

@Test func aggregateHeatIsZeroWhenNothingScheduled() {
    let h = checkHabit(.week([0]))   // Sunday-only
    let items = [HabitDerivations.HabitData(spec: h, logs: [:])]
    let monday = DayKey.addDays(refToday, -6) // Mon 6/15, not scheduled
    #expect(HabitDerivations.aggregateHeatLevel(items, on: monday, today: refToday) == 0)
}

@Test func aggregateHeatFullCompletionIsFour() {
    let h1 = checkHabit(); let h2 = checkHabit()
    let done = logs([1: 1])
    let items = [HabitDerivations.HabitData(spec: h1, logs: done),
                 HabitDerivations.HabitData(spec: h2, logs: done)]
    let yesterday = DayKey.addDays(refToday, -1)
    #expect(HabitDerivations.aggregateHeatLevel(items, on: yesterday, today: refToday) == 4)
}

@Test func aggregateHeatFutureIsBlank() {
    let h = checkHabit()
    let items = [HabitDerivations.HabitData(spec: h, logs: [:])]
    let tomorrow = DayKey.addDays(refToday, 1)
    #expect(HabitDerivations.aggregateHeatLevel(items, on: tomorrow, today: refToday) == -1)
}

// MARK: - perfect days

@Test func perfectDaysCountsAllScheduledDoneAndIgnoresEmptyDays() {
    let h1 = checkHabit()
    let h2 = checkHabit()
    // yesterday: both done → perfect. two days ago: only h1 done → not perfect.
    let items = [
        HabitDerivations.HabitData(spec: h1, logs: logs([1: 1, 2: 1])),
        HabitDerivations.HabitData(spec: h2, logs: logs([1: 1])),
    ]
    #expect(HabitDerivations.perfectDays(items, days: 3, today: refToday) == 1)
}

// MARK: - day-of-week & weekly trend bucketing

@Test func dowRatesReturnsSevenBucketsIndexedSunToSat() {
    let h = checkHabit()
    let items = [HabitDerivations.HabitData(spec: h, logs: logs([1: 1]))]
    let rates = HabitDerivations.dowRates(items, days: 84, today: refToday)
    #expect(rates.count == 7)
    // offset 1 = Sat 6/20 → index 6 should be > 0
    #expect(rates[6] > 0)
}

@Test func weeklyTrendReturnsRequestedNumberOfWeeksOldestFirst() {
    let h = checkHabit()
    let items = [HabitDerivations.HabitData(spec: h, logs: logs([1: 1, 2: 1, 3: 1]))]
    let trend = HabitDerivations.weeklyTrend(items, weeks: 8, today: refToday)
    #expect(trend.count == 8)
    #expect(trend.last! > 0)   // most recent week has completions
}
