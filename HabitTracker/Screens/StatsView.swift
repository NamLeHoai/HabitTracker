//
//  StatsView.swift
//  HabitTracker
//
//  Insights tab: summary cards, 18-week activity heatmap, best-day-of-week bars,
//  weekly trend, and per-habit rows. All values come from cached store stats.
//

import SwiftUI

struct StatsView: View {
    var openDetail: (Habit) -> Void
    @Environment(HabitStore.self) private var store
    @Environment(ThemeManager.self) private var theme
    @Environment(\.theme) private var t

    private var g: GlobalStats { store.global }
    private let dowLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let dowNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Insights").font(.system(size: 30, weight: .heavy, design: .rounded))
                    Text("Last 30 days").font(.system(size: 13.5, weight: .semibold)).foregroundStyle(t.sub)
                }
                Spacer()
                Button { theme.toggle() } label: {
                    Text(theme.isDark ? "☀️" : "🌙").font(.system(size: 17))
                        .glassChrome(diameter: 40)
                }
            }
            .padding(.horizontal, 20).padding(.top, 62).padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    levelCard
                    summaryCards
                    activityCard
                    bestDayCard
                    weeklyTrendCard
                    achievementsSection
                    perHabitSection
                }
                .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 120)
            }
        }
    }

    private var levelCard: some View {
        LevelBar(info: Level.info(forXP: g.xp))
            .padding(18)
            .frame(maxWidth: .infinity)
            .glassCard(cornerRadius: 22)
    }

    private var achievementsSection: some View {
        let badges = Achievements.all(for: g)
        let earned = badges.filter(\.isEarned).count
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("ACHIEVEMENTS").font(.system(size: 13, weight: .bold)).tracking(0.6).foregroundStyle(t.sub)
                Spacer()
                Text("\(earned)/\(badges.count)").font(.system(size: 13, weight: .bold)).foregroundStyle(t.acc)
            }
            .padding(.horizontal, 4).padding(.bottom, 12)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 16) {
                ForEach(badges) { AchievementBadge(achievement: $0) }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .glassCard(cornerRadius: 22)
        }
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            statCard("Completion", "\(Int(g.avgCompletion30 * 100))%", accent: true)
            statCard("Best streak", "\(g.bestStreak) 🔥")
            statCard("Check-ins", "\(g.totalCheckins)")
            statCard("Perfect days", "\(g.perfectDays30) ⭐")
        }
    }

    private func statCard(_ title: String, _ value: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(t.sub)
            Text(value).font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(accent ? t.acc : t.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 17).padding(.vertical, 16)
        .glassCard(cornerRadius: 20)
    }

    private var activityCard: some View {
        card {
            VStack(alignment: .leading, spacing: 0) {
                Text("Activity").font(.system(size: 15.5, weight: .bold))
                Text("Last 18 weeks").font(.system(size: 12.5)).foregroundStyle(t.sub)
                    .padding(.top, 2).padding(.bottom, 14)
                Heatmap(weeks: g.aggregateHeat, color: t.acc, pill: t.pill)
                HStack(spacing: 5) {
                    Spacer()
                    Text("Less").font(.system(size: 11)).foregroundStyle(t.sub)
                    ForEach([0, 2, 4], id: \.self) { lvl in
                        RoundedRectangle(cornerRadius: 3).fill(Heatmap.fill(level: lvl, color: t.acc, pill: t.pill))
                            .frame(width: 11, height: 11)
                    }
                    Text("More").font(.system(size: 11)).foregroundStyle(t.sub)
                }
                .padding(.top, 12)
            }
        }
    }

    private var bestDayCard: some View {
        let maxR = max(g.dowRates.max() ?? 0.01, 0.01)
        let bestIdx = g.dowRates.indices.max(by: { g.dowRates[$0] < g.dowRates[$1] }) ?? 0
        return card {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Best day of week").font(.system(size: 15.5, weight: .bold))
                    Spacer()
                    Text(dowNames[bestIdx]).font(.system(size: 13.5, weight: .bold)).foregroundStyle(t.acc)
                }
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<7, id: \.self) { i in
                        VStack(spacing: 6) {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(i == bestIdx ? t.acc : t.acc.opacity(0.30))
                                .frame(height: max(6, CGFloat(g.dowRates[i] / maxR) * 80))
                            Text(dowLabels[i]).font(.system(size: 11, weight: .semibold)).foregroundStyle(t.sub)
                        }
                    }
                }
                .frame(height: 96).padding(.top, 16)
            }
        }
    }

    private var weeklyTrendCard: some View {
        let maxW = max(g.weeklyTrend.max() ?? 0.01, 0.01)
        return card {
            VStack(alignment: .leading, spacing: 0) {
                Text("Weekly trend").font(.system(size: 15.5, weight: .bold))
                HStack(alignment: .bottom, spacing: 7) {
                    ForEach(Array(g.weeklyTrend.enumerated()), id: \.offset) { i, r in
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(i == g.weeklyTrend.count - 1 ? t.acc : t.acc.opacity(0.35))
                            .frame(maxWidth: .infinity)
                            .frame(height: max(8, CGFloat(r / maxW) * 80))
                    }
                }
                .frame(height: 80).padding(.top, 16)
                HStack {
                    Text("8 wks ago").font(.system(size: 11)).foregroundStyle(t.sub)
                    Spacer()
                    Text("This week").font(.system(size: 11)).foregroundStyle(t.sub)
                }
                .padding(.top, 8)
            }
        }
    }

    private var perHabitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PER HABIT").font(.system(size: 13, weight: .bold)).tracking(0.6)
                .foregroundStyle(t.sub).padding(.horizontal, 4).padding(.top, 12)
            ForEach(store.habits) { habit in
                let color = Color(hex: habit.colorHex)
                let s = store.stats(for: habit)
                Button { openDetail(habit) } label: {
                    HStack(spacing: 13) {
                        Text(habit.icon).font(.system(size: 20))
                            .frame(width: 40, height: 40)
                            .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(habit.name).font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Text("\(Int(s.rate30 * 100))%").font(.system(size: 13, weight: .bold)).foregroundStyle(color)
                            }
                            ProgressView(value: s.rate30).tint(color).background(t.pill)
                                .frame(height: 6).clipShape(Capsule())
                        }
                        Text("🔥\(s.streak)").font(.system(size: 13, weight: .bold)).foregroundStyle(t.sub)
                    }
                    .padding(.horizontal, 15).padding(.vertical, 13)
                    .glassCard(cornerRadius: 18)
                }
                .buttonStyle(.plain)
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
