//
//  RootView.swift
//  HabitTracker
//
//  App shell: onboarding gate, the four tabs, custom bottom nav with center FAB,
//  and the Detail / Create presentations. Replaces the template ContentView.
//

import SwiftUI

enum Tab: Hashable { case today, stats, mood, focus }

struct RootView: View {
    @Environment(HabitStore.self) private var store
    @Environment(ThemeManager.self) private var theme
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @State private var tab: Tab = .today
    @State private var detailHabit: Habit?
    @State private var showCreate = false

    private var t: ThemeTokens { theme.tokens }

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()

            if !hasSeenOnboarding {
                OnboardingView { hasSeenOnboarding = true }
                    .transition(.opacity)
            } else {
                ZStack(alignment: .bottom) {
                    Group {
                        switch tab {
                        case .today: TodayView(openDetail: { detailHabit = $0 })
                        case .stats: StatsView(openDetail: { detailHabit = $0 })
                        case .mood: MoodView()
                        case .focus: FocusView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    TabBar(tab: $tab, onCreate: { showCreate = true })
                }
            }
        }
        .environment(\.theme, t)
        .tint(t.acc)
        .font(.system(.body, design: .rounded))
        .foregroundStyle(t.text)
        .animation(.easeInOut(duration: 0.25), value: hasSeenOnboarding)
        .sheet(item: $detailHabit) { habit in
            HabitDetailView(habit: habit)
                .environment(store)
                .environment(theme)
                .environment(\.theme, t)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCreate) {
            CreateHabitView()
                .environment(store)
                .environment(theme)
                .environment(\.theme, t)
        }
    }
}

private struct TabBar: View {
    @Binding var tab: Tab
    var onCreate: () -> Void
    @Environment(\.theme) private var t

    var body: some View {
        HStack(spacing: 0) {
            item(.today, "checklist", "Today")
            item(.stats, "chart.bar.fill", "Stats")

            Button(action: onCreate) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(
                        LinearGradient(colors: [t.acc, Color(hex: "#FFB23E")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .shadow(color: t.acc.opacity(0.45), radius: 9, y: 8)
            }
            .offset(y: -18)
            .frame(maxWidth: .infinity)

            item(.mood, "face.smiling.fill", "Mood")
            item(.focus, "timer", "Focus")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(t.nav, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(t.sep, lineWidth: 1))
        .shadow(color: t.shadow, radius: 12, y: 6)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func item(_ value: Tab, _ icon: String, _ label: String) -> some View {
        Button { tab = value } label: {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 21, weight: .semibold))
                Text(label).font(.system(size: 10.5, weight: .semibold))
            }
            .foregroundStyle(tab == value ? t.acc : t.faint)
            .frame(maxWidth: .infinity)
        }
    }
}
