//
//  TodayView.swift
//  HabitTracker
//
//  The home tab. Two layout "directions" (A = list, B = grid) mirroring the prototype,
//  plus the daily progress ring and the mood quick-pick.
//

import SwiftUI

struct TodayView: View {
    var openDetail: (Habit) -> Void
    @Environment(HabitStore.self) private var store
    @Environment(ThemeManager.self) private var theme
    @Environment(\.theme) private var t
    @AppStorage("layoutB") private var layoutB = false
    @State private var toggleTick = 0

    private var habits: [Habit] { store.todayHabits }

    /// Toggle today's completion and fire a success haptic.
    private func toggle(_ habit: Habit) {
        store.toggleToday(habit)
        toggleTick += 1
    }
    private var doneCount: Int { habits.filter { store.isDone($0, on: store.today) }.count }
    private var total: Int { habits.count }
    private var pct: Double { total > 0 ? Double(doneCount) / Double(total) : 0 }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if layoutB { directionB } else { directionA }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 120)
            }
        }
        .sensoryFeedback(.success, trigger: toggleTick)
    }

    // MARK: Header

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting).font(.system(size: 15, weight: .semibold)).foregroundStyle(t.acc)
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
            }
            Spacer()
            HStack(spacing: 9) {
                HStack(spacing: 2) {
                    segLabel("A", active: !layoutB)
                    segLabel("B", active: layoutB)
                }
                .padding(3)
                .background(t.pill, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .onTapGesture { withAnimation { layoutB.toggle() } }

                Button { theme.toggle() } label: {
                    Text(theme.isDark ? "☀️" : "🌙").font(.system(size: 17))
                        .glassChrome(diameter: 40)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 62)
        .padding(.bottom, 10)
    }

    private func segLabel(_ s: String, active: Bool) -> some View {
        Text(s)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(active ? t.acc : t.sub)
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(active ? t.card : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: Direction A

    private var directionA: some View {
        VStack(spacing: 0) {
            progressCard
                .padding(.bottom, 22)

            sectionLabel("DUE TODAY")
            VStack(spacing: 12) {
                ForEach(habits) { habit in
                    habitRow(habit)
                }
            }
            moodCard.padding(.top, 22)
        }
    }

    private var progressCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("TODAY'S PROGRESS").font(.system(size: 13, weight: .semibold)).opacity(0.9)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(doneCount)").font(.system(size: 34, weight: .heavy, design: .rounded))
                    Text(" / \(total)").font(.system(size: 22, weight: .bold)).opacity(0.7)
                }
                .padding(.top, 3)
                Text(dayMessage).font(.system(size: 13.5)).opacity(0.92).padding(.top, 5)
            }
            Spacer()
            ProgressRing(progress: pct, lineWidth: 8,
                         trackColor: .white.opacity(0.28), ringColor: .white) {
                Text("\(Int(pct * 100))%").font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 74, height: 74)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 22).padding(.vertical, 20)
        .background(Brand.iridescent(t), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(.white.opacity(0.25), lineWidth: 1))
        .shadow(color: t.acc.opacity(0.4), radius: 16, y: 12)
    }

    private var dayMessage: String {
        if pct >= 1 { return "All done — amazing! 🎉" }
        if pct >= 0.5 { return "Great momentum, keep going!" }
        return "Let’s build some momentum"
    }

    private func habitRow(_ habit: Habit) -> some View {
        let color = Color(hex: habit.colorHex)
        let v = store.value(habit, on: store.today)
        let done = store.isDone(habit, on: store.today)
        let p = progress(habit, value: v)
        return HStack(spacing: 14) {
            Text(habit.icon).font(.system(size: 23))
                .frame(width: 46, height: 46)
                .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name).font(.system(size: 16.5, weight: .semibold))
                HStack(spacing: 6) {
                    if habit.kind == .quit {
                        Text("QUIT").font(.system(size: 9.5, weight: .heavy))
                            .foregroundStyle(color)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: 5))
                    }
                    Text(subtitle(habit, value: v, done: done))
                        .font(.system(size: 13)).foregroundStyle(t.sub)
                }
            }
            Spacer(minLength: 8)
            Button { toggle(habit) } label: {
                ZStack {
                    MiniRing(progress: p, color: color, trackColor: color.opacity(0.17))
                    Text(done ? "✓" : (habit.goal.isMeasure && v > 0 ? "\(v)" : ""))
                        .font(.system(size: done ? 19 : 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(color)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .glassCard(cornerRadius: 22)
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(color.opacity(0.30), lineWidth: 1.5))
        .contentShape(Rectangle())
        .onTapGesture { openDetail(habit) }
    }

    // MARK: Direction B

    private var directionB: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                ProgressRing(progress: pct, lineWidth: 20,
                             trackColor: t.pill, ringColor: t.acc) {
                    VStack(spacing: 4) {
                        Text("\(Int(pct * 100))%")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                        Text("\(doneCount) of \(total) done")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(t.sub)
                    }
                }
                .frame(width: 212, height: 212)
                .padding(.top, 8)

                HStack(spacing: 10) {
                    pill("🔥 \(store.global.bestStreak) day streak", color: Color(hex: "#FF6B5E"))
                    pill("⚡ \(doneCount * 40) XP", color: Color(hex: "#E0911C"))
                }
            }
            .frame(maxWidth: .infinity)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(habits) { habit in
                    chip(habit)
                }
            }
            .padding(.top, 22)
        }
    }

    private func chip(_ habit: Habit) -> some View {
        let color = Color(hex: habit.colorHex)
        let v = store.value(habit, on: store.today)
        let done = store.isDone(habit, on: store.today)
        let p = progress(habit, value: v)
        let inner = VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(habit.icon).font(.system(size: 22))
                    .frame(width: 42, height: 42)
                    .background((done ? Color.white.opacity(0.22) : color.opacity(0.16)),
                                in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                Spacer()
                Text(done ? "✓" : "")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(done ? .white : t.sub)
                    .frame(width: 26, height: 26)
                    .background((done ? Color.white.opacity(0.25) : t.pill), in: Circle())
            }
            Text(habit.name).font(.system(size: 15, weight: .bold)).padding(.top, 12)
            Text(subtitle(habit, value: v, done: done))
                .font(.system(size: 12.5, weight: .semibold)).opacity(0.75).padding(.top, 2)
            ProgressView(value: p)
                .tint(done ? .white : color)
                .background(done ? Color.white.opacity(0.25) : t.pill)
                .frame(height: 6).clipShape(Capsule())
                .padding(.top, 10)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(done ? .white : t.text)

        return Button { toggle(habit) } label: {
            if done {
                inner
                    .background(Brand.sweep(color), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.30), lineWidth: 1))
                    .shadow(color: color.opacity(0.4), radius: 12, y: 8)
            } else {
                inner
                    .glassCard(cornerRadius: 20)
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(color.opacity(0.22), lineWidth: 1.5))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Mood quick-pick

    private var moodCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("How are you feeling?").font(.system(size: 15.5, weight: .bold))
            MoodPicker(selected: store.todayMood) { store.setMood($0) }
                .padding(.top, 14)
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22)
    }

    // MARK: Helpers

    private func pill(_ text: String, color: Color) -> some View {
        Text(text).font(.system(size: 14, weight: .bold)).foregroundStyle(color)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func sectionLabel(_ s: String) -> some View {
        Text(s).font(.system(size: 13, weight: .bold)).foregroundStyle(t.sub)
            .tracking(0.6).frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4).padding(.bottom, 12)
    }

    private func progress(_ habit: Habit, value v: Int) -> Double {
        switch habit.goal {
        case .check: return store.isDone(habit, on: store.today) ? 1 : 0
        case .measure(let target, _): return target > 0 ? min(1, Double(v) / Double(target)) : 0
        }
    }

    private func subtitle(_ habit: Habit, value v: Int, done: Bool) -> String {
        switch habit.goal {
        case .measure(let target, _):
            return "\(v) / \(target) \(habit.unit)"
        case .check:
            if habit.kind == .quit { return done ? "Stayed clean today" : "Avoid today" }
            return done ? "Completed" : "Tap to complete"
        }
    }
}

extension Goal {
    var isMeasure: Bool { if case .measure = self { return true }; return false }
}
