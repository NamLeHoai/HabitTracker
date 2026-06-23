//
//  HabitSpec.swift
//  HabitTracker
//
//  Pure value types describing a habit's behavior, decoupled from SwiftData.
//  The derivation layer operates on these so it stays testable without a model context.
//

import Foundation

enum HabitKind: String, Codable, CaseIterable {
    case build
    case quit
}

enum GoalKind: String, Codable, CaseIterable {
    case check
    case measure
}

/// When a habit is due. Weekday indices are 0 = Sunday ... 6 = Saturday (matches the prototype's `getDay()`).
enum Schedule: Equatable {
    case daily
    case week([Int])
}

/// How completion is measured.
enum Goal: Equatable {
    case check
    case measure(target: Int, step: Int)
}

/// Immutable snapshot of a habit used by `HabitDerivations`.
struct HabitSpec: Equatable {
    let id: String
    let kind: HabitKind
    let schedule: Schedule
    let goal: Goal
}
