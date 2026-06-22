//
//  SeedData.swift
//  HabitTracker
//
//  First-run seed of the seven prototype habits. No fake history — real usage drives all stats.
//

import Foundation
import SwiftData

enum SeedData {
    static func seed(into context: ModelContext) {
        let seeds: [Habit] = [
            Habit(id: "water", name: "Drink Water", icon: "💧", colorHex: Palette.blue,
                  category: "Health", kind: .build, schedule: .daily,
                  goal: .measure(target: 8, step: 1), unit: "glasses", sortOrder: 0),
            Habit(id: "run", name: "Morning Run", icon: "🏃", colorHex: Palette.coral,
                  category: "Fitness", kind: .build, schedule: .week([1, 3, 5]),
                  goal: .measure(target: 30, step: 5), unit: "min", sortOrder: 1),
            Habit(id: "read", name: "Read", icon: "📖", colorHex: Palette.amber,
                  category: "Mind", kind: .build, schedule: .daily,
                  goal: .measure(target: 30, step: 10), unit: "min", sortOrder: 2),
            Habit(id: "meditate", name: "Meditate", icon: "🧘", colorHex: Palette.indigo,
                  category: "Mind", kind: .build, schedule: .daily, goal: .check, sortOrder: 3),
            Habit(id: "vitamins", name: "Vitamins", icon: "💊", colorHex: Palette.green,
                  category: "Health", kind: .build, schedule: .daily, goal: .check, sortOrder: 4),
            Habit(id: "sugar", name: "No Sugar", icon: "🍩", colorHex: Palette.pink,
                  category: "Health", kind: .quit, schedule: .daily, goal: .check, sortOrder: 5),
            Habit(id: "sleep", name: "Sleep by 11", icon: "🌙", colorHex: Palette.teal,
                  category: "Sleep", kind: .build, schedule: .daily, goal: .check, sortOrder: 6),
        ]
        for habit in seeds { context.insert(habit) }
        try? context.save()
    }
}
