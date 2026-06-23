//
//  HabitTrackerWidget.swift
//  HabitTrackerWidget
//
//  Home Screen (small/medium) and Lock Screen (circular/rectangular/inline) widgets showing
//  today's habit progress. Data comes from the App Group snapshot the app publishes — no live
//  SwiftData access here. Read-only for now; interactive toggling (App Intents) is a follow-up.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline

struct HabitEntry: TimelineEntry {
    let date: Date
    let snapshot: HabitSnapshot
}

struct HabitProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        let snap = context.isPreview ? .sample : SnapshotStore.read()
        completion(HabitEntry(date: Date(), snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let entry = HabitEntry(date: Date(), snapshot: SnapshotStore.read())
        // The app reloads timelines on every change; this just refreshes the ring after midnight.
        let nextMidnight = Calendar.current.nextDate(
            after: Date(), matching: DateComponents(hour: 0, minute: 1), matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

// MARK: - Widget

@main
struct HabitTrackerWidgetBundle: WidgetBundle {
    var body: some Widget { HabitTrackerWidget() }
}

struct HabitTrackerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HabitTrackerWidget", provider: HabitProvider()) { entry in
            HabitWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Habits")
        .description("Your daily habit progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Views

struct HabitWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HabitEntry

    private var snap: HabitSnapshot { entry.snapshot }

    var body: some View {
        switch family {
        case .systemMedium:        mediumView
        case .accessoryCircular:   accessoryCircular
        case .accessoryRectangular: accessoryRectangular
        case .accessoryInline:     accessoryInline
        default:                   smallView
        }
    }

    // Home Screen — small: ring + count
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY").font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
            HStack {
                ProgressRing(fraction: snap.fraction, lineWidth: 9) {
                    Text("\(Int(snap.fraction * 100))%")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 58, height: 58)
                Spacer()
            }
            Spacer()
            Text("\(snap.doneCount) of \(snap.total) done")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
        .containerBackground(for: .widget) { brandGradient }
    }

    // Home Screen — medium: ring + a few habits
    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                ProgressRing(fraction: snap.fraction, lineWidth: 10) {
                    VStack(spacing: 0) {
                        Text("\(snap.doneCount)/\(snap.total)")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 72, height: 72)
                Text("🔥 \(snap.bestStreak)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
            VStack(alignment: .leading, spacing: 6) {
                if snap.items.isEmpty {
                    Text("No habits today").font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                } else {
                    ForEach(snap.items.prefix(4)) { item in
                        HStack(spacing: 8) {
                            Text(item.icon).font(.system(size: 14))
                            Text(item.name).font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white).lineLimit(1)
                            Spacer(minLength: 2)
                            Button(intent: ToggleHabitIntent(habitID: item.id)) {
                                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white.opacity(item.done ? 1 : 0.55))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) { brandGradient }
    }

    // Lock Screen — circular gauge
    private var accessoryCircular: some View {
        Gauge(value: snap.fraction) {
            Text("\(snap.doneCount)")
        } currentValueLabel: {
            Text("\(snap.doneCount)")
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .containerBackground(.clear, for: .widget)
    }

    // Lock Screen — rectangular
    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Today's Habits").font(.headline)
            Text("\(snap.doneCount) of \(snap.total) done")
            ProgressView(value: snap.fraction).tint(.white)
        }
        .containerBackground(.clear, for: .widget)
    }

    // Lock Screen — inline
    private var accessoryInline: some View {
        Text("✅ \(snap.doneCount)/\(snap.total) habits")
            .containerBackground(.clear, for: .widget)
    }

    private var brandGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#7C5CFF"), Color(hex: "#B06BFF"), Color(hex: "#16C8B8")],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Small reusable ring (widget-local)

private struct ProgressRing<Content: View>: View {
    var fraction: Double
    var lineWidth: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.28), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, fraction)))
                .stroke(.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            content()
        }
    }
}

// MARK: - Color hex (widget-local copy)

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

#Preview(as: .systemSmall) {
    HabitTrackerWidget()
} timeline: {
    HabitEntry(date: Date(), snapshot: .sample)
}
