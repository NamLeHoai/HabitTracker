//
//  LevelBar.swift
//  HabitTracker
//
//  Compact level + XP progress display. Reads a precomputed LevelInfo (never derives in body).
//

import SwiftUI

struct LevelBar: View {
    let info: LevelInfo
    @Environment(\.theme) private var t

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Lv \(info.level)")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(t.acc)
                Text(info.title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(t.sub)
                Spacer()
                Text("\(info.xp) XP")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(t.sub)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(t.pill)
                    Capsule().fill(Brand.iridescent(t))
                        .frame(width: max(6, geo.size.width * info.progress))
                }
            }
            .frame(height: 9)
            Text("\(info.xpToNext) XP to level \(info.level + 1)")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(t.faint)
        }
        .animation(.easeOut(duration: 0.4), value: info.xp)
    }
}
