//
//  MoodView.swift
//  HabitTracker
//

import SwiftUI

struct MoodView: View {
    @Environment(HabitStore.self) private var store
    @Environment(ThemeManager.self) private var theme
    @Environment(\.theme) private var t

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var moods: [String: Int] { store.moodIndex }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Mood").font(.system(size: 30, weight: .heavy, design: .rounded))
                Spacer()
                Button { theme.toggle() } label: {
                    Text(theme.isDark ? "☀️" : "🌙").font(.system(size: 17))
                        .glassChrome(diameter: 40)
                }
            }
            .padding(.horizontal, 20).padding(.top, 62).padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    averageCard
                    weekCard
                    pickCard
                    distributionCard
                }
                .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 120)
            }
        }
    }

    private var average: Double {
        let v = Array(moods.values)
        return v.isEmpty ? 0 : Double(v.reduce(0, +)) / Double(v.count)
    }

    private var averageCard: some View {
        HStack(spacing: 18) {
            Text(average > 0 ? (Mood.emoji[Int(average.rounded())] ?? "😐") : "😐")
                .font(.system(size: 58))
            VStack(alignment: .leading, spacing: 4) {
                Text(average > 0 ? String(format: "%.1f / 5 average", average) : "No data yet")
                    .font(.system(size: 21, weight: .heavy, design: .rounded))
                Text("This month · \(moods.count) days").font(.system(size: 13.5)).opacity(0.92)
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(22)
        .background(
            LinearGradient(colors: [Color(hex: "#34C77B"), Color(hex: "#1FC6B8")],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.25), lineWidth: 1))
        .shadow(color: Color(hex: "#1FC6B8").opacity(0.34), radius: 16, y: 12)
    }

    private var weekCard: some View {
        card {
            VStack(alignment: .leading, spacing: 0) {
                Text("This week").font(.system(size: 15.5, weight: .bold)).padding(.bottom, 16)
                HStack(alignment: .bottom, spacing: 9) {
                    ForEach(0..<7, id: \.self) { i in
                        let date = DayKey.addDays(store.today, -(6 - i))
                        let mv = moods[DayKey.key(date)] ?? 0
                        VStack(spacing: 7) {
                            Text(mv > 0 ? (Mood.emoji[mv] ?? "") : "·").font(.system(size: 15))
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(mv > 0 ? (Mood.color[mv] ?? t.pill) : t.pill)
                                .frame(height: max(6, CGFloat(mv) / 5 * 88))
                            Text(dayLabels[DayKey.weekdayIndex(date)])
                                .font(.system(size: 11, weight: .semibold)).foregroundStyle(t.sub)
                        }
                    }
                }
                .frame(height: 110)
            }
        }
    }

    private var pickCard: some View {
        card {
            VStack(alignment: .leading, spacing: 0) {
                Text("How are you today?").font(.system(size: 15.5, weight: .bold))
                MoodPicker(selected: store.todayMood) { store.setMood($0) }.padding(.top, 14)
            }
        }
    }

    private var distributionCard: some View {
        let values = Array(moods.values)
        return card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Distribution").font(.system(size: 15.5, weight: .bold))
                ForEach([5, 4, 3, 2, 1], id: \.self) { n in
                    let count = values.filter { $0 == n }.count
                    let frac = values.isEmpty ? 0 : Double(count) / Double(values.count)
                    HStack(spacing: 12) {
                        Text(Mood.emoji[n] ?? "").font(.system(size: 21)).frame(width: 26)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(t.pill)
                                Capsule().fill(Mood.color[n] ?? t.acc)
                                    .frame(width: max(0, geo.size.width * frac))
                            }
                        }
                        .frame(height: 9)
                        Text("\(Int(frac * 100))%").font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(t.sub).frame(width: 34, alignment: .trailing)
                    }
                }
            }
        }
    }

    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22)
    }
}
