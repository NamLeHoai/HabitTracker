//
//  HabitDetailView.swift
//  HabitTracker
//
//  Per-habit detail: streak hero, stat trio, month calendar, 18-week heatmap.
//  Calendar/heatmap are computed once on appear (never in `body`).
//

import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @Environment(HabitStore.self) private var store
    @Environment(\.theme) private var t
    @Environment(\.dismiss) private var dismiss

    @State private var calCells: [CalCell] = []
    @State private var heat: [[Int]] = []
    @State private var confirmDelete = false
    @State private var showEdit = false

    private var color: Color { Color(hex: habit.colorHex) }

    struct CalCell: Identifiable {
        let id = UUID()
        let label: String
        let kind: Kind
        enum Kind { case blank, unscheduled, future, done, missed, today }
    }

    var body: some View {
        let s = store.stats(for: habit)
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                topBar
                headerRow
                streakHero(s)
                statTrio(s)
                calendarCard
                heatmapCard
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AmbientBackground())
        .onAppear(perform: rebuild)
        .confirmationDialog("Delete this habit?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { store.deleteHabit(habit); dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes “\(habit.name)” and all its history.")
        }
        .sheet(isPresented: $showEdit, onDismiss: rebuild) {
            CreateHabitView(editing: habit)
                .environment(store)
                .environment(\.theme, t)
                .presentationDragIndicator(.visible)
        }
    }

    private var topBar: some View {
        HStack {
            circleButton("chevron.left") { dismiss() }
            Spacer()
            Menu {
                Button { showEdit = true } label: {
                    Label("Edit Habit", systemImage: "pencil")
                }
                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete Habit", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 17, weight: .bold))
                    .foregroundStyle(t.sub)
                    .glassChrome(diameter: 40)
            }
        }
        .padding(.top, 8)
    }

    private var headerRow: some View {
        HStack(spacing: 14) {
            Text(habit.icon).font(.system(size: 30))
                .frame(width: 58, height: 58)
                .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(habit.name).font(.system(size: 25, weight: .heavy, design: .rounded))
                Text("\(habit.kind == .quit ? "Quit · " : "")\(habit.category) · \(schedLabel)")
                    .font(.system(size: 13.5, weight: .semibold)).foregroundStyle(t.sub)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var schedLabel: String {
        switch habit.schedule {
        case .daily: return "Every day"
        case .week(let days):
            let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return days.sorted().map { names[$0] }.joined(separator: " · ")
        }
    }

    private func streakHero(_ s: HabitStats) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("CURRENT STREAK").font(.system(size: 13, weight: .semibold)).opacity(0.92)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(s.streak)").font(.system(size: 46, weight: .black, design: .rounded))
                    Text(" days").font(.system(size: 19, weight: .bold)).opacity(0.85)
                }
                .padding(.top, 4)
            }
            Spacer()
            Text("🔥").font(.system(size: 46))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 22).padding(.vertical, 20)
        .background(Brand.sweep(color), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.25), lineWidth: 1))
        .shadow(color: color.opacity(0.4), radius: 16, y: 12)
    }

    private func statTrio(_ s: HabitStats) -> some View {
        HStack(spacing: 10) {
            miniStat("\(s.best)", "Best", color: t.text)
            miniStat("\(Int(s.rate30 * 100))%", "30-day", color: color)
            miniStat("\(s.totalDone)", "Total", color: t.text)
        }
    }

    private func miniStat(_ value: String, _ label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(color)
            Text(label).font(.system(size: 11.5, weight: .semibold)).foregroundStyle(t.sub)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .glassCard(cornerRadius: 16)
    }

    private var calendarCard: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
        return VStack(alignment: .leading, spacing: 0) {
            Text(store.today.formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 16, weight: .bold)).padding(.bottom, 14)
            LazyVGrid(columns: cols, spacing: 5) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"].indices, id: \.self) { i in
                    Text(["S", "M", "T", "W", "T", "F", "S"][i])
                        .font(.system(size: 11.5, weight: .bold)).foregroundStyle(t.faint)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 6)
            LazyVGrid(columns: cols, spacing: 5) {
                ForEach(calCells) { cell in calCellView(cell) }
            }
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22)
    }

    private func calCellView(_ cell: CalCell) -> some View {
        Group {
            switch cell.kind {
            case .blank:
                Color.clear
            case .done:
                Text(cell.label).font(.system(size: 13.5, weight: .heavy)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                    .background(color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            case .today:
                Text(cell.label).font(.system(size: 13.5, weight: .heavy)).foregroundStyle(color)
                    .frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(color, lineWidth: 2))
            case .missed:
                Text(cell.label).font(.system(size: 13.5, weight: .semibold)).foregroundStyle(t.sub)
                    .frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(color.opacity(0.32), lineWidth: 1.5))
            case .future, .unscheduled:
                Text(cell.label).font(.system(size: 13.5, weight: .semibold)).foregroundStyle(t.faint)
                    .frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
            }
        }
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Last 18 weeks").font(.system(size: 16, weight: .bold)).padding(.bottom, 14)
            Heatmap(weeks: heat, color: color, pill: t.pill)
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22)
    }

    private func circleButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 15, weight: .bold)).foregroundStyle(t.sub)
                .glassChrome(diameter: 40)
        }
    }

    // MARK: Build calendar + heatmap once

    private func rebuild() {
        heat = store.heatGrid(for: habit)
        calCells = buildCalendar()
    }

    private func buildCalendar() -> [CalCell] {
        let cal = DayKey.calendar
        let today = store.today
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: today)) ?? today
        let leading = DayKey.weekdayIndex(monthStart)   // 0 = Sun
        let dayCount = cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30

        var cells: [CalCell] = []
        for _ in 0..<leading { cells.append(CalCell(label: "", kind: .blank)) }
        for day in 1...dayCount {
            guard let date = cal.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            let isToday = DayKey.key(date) == DayKey.key(today)
            let future = DayKey.startOfDay(date) > DayKey.startOfDay(today) && !isToday
            let done = store.isDone(habit, on: date)
            let scheduled = store.isScheduled(habit, on: date)

            let kind: CalCell.Kind
            if !scheduled { kind = .unscheduled }
            else if done { kind = .done }
            else if isToday { kind = .today }
            else if future { kind = .future }
            else { kind = .missed }
            cells.append(CalCell(label: "\(day)", kind: kind))
        }
        return cells
    }
}
