//
//  MoodPicker.swift
//  HabitTracker
//
//  Shared 1...5 mood selector used by both Today and Mood screens (both write the same store).
//

import SwiftUI

enum Mood {
    static let emoji: [Int: String] = [1: "😣", 2: "😕", 3: "😐", 4: "🙂", 5: "😄"]
    static let color: [Int: Color] = [
        1: Color(hex: "#FF6B5E"), 2: Color(hex: "#FF9A52"), 3: Color(hex: "#FFC83E"),
        4: Color(hex: "#34C77B"), 5: Color(hex: "#1FC6B8"),
    ]
}

struct MoodPicker: View {
    var selected: Int
    var onPick: (Int) -> Void
    @Environment(\.theme) private var t

    var body: some View {
        HStack {
            ForEach(1...5, id: \.self) { n in
                let isSel = selected == n
                Button { onPick(n) } label: {
                    Text(Mood.emoji[n] ?? "")
                        .font(.system(size: 25))
                        .frame(width: 48, height: 48)
                        .background(isSel ? (Mood.color[n] ?? t.acc).opacity(0.22) : t.pill,
                                    in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(isSel ? (Mood.color[n] ?? t.acc) : .clear, lineWidth: 2)
                        )
                        .scaleEffect(isSel ? 1.12 : 1)
                }
                .buttonStyle(.plain)
                if n < 5 { Spacer() }
            }
        }
        .animation(.easeOut(duration: 0.15), value: selected)
    }
}
