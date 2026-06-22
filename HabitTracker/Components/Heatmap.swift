//
//  Heatmap.swift
//  HabitTracker
//
//  GitHub-style contribution grid. Takes precomputed levels (see HabitDerivations.heatGrid):
//  -1 blank/future, 0 empty, 1...4 increasing intensity.
//

import SwiftUI

struct Heatmap: View {
    var weeks: [[Int]]      // columns of 7 levels
    var color: Color        // accent for this grid
    var pill: Color         // empty-cell color
    var cell: CGFloat = 13
    var spacing: CGFloat = 3

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: spacing) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, column in
                    VStack(spacing: spacing) {
                        ForEach(Array(column.enumerated()), id: \.offset) { _, level in
                            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                .fill(Heatmap.fill(level: level, color: color, pill: pill))
                                .frame(width: cell, height: cell)
                        }
                    }
                }
            }
        }
    }

    static func fill(level: Int, color: Color, pill: Color) -> Color {
        switch level {
        case -1: return .clear
        case 1: return color.opacity(0.28)
        case 2: return color.opacity(0.50)
        case 3: return color.opacity(0.72)
        case 4: return color
        default: return pill   // 0
        }
    }
}
