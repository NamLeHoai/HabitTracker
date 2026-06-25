//
//  HabitTrackerWidget.swift
//  HabitTrackerWidget
//
//  Home Screen (small/medium) and Lock Screen (circular/rectangular/inline) widgets showing
//  today's habit progress. Data comes from the App Group snapshot the app publishes. Appearance
//  (background / light-dark / text color) is user-configurable via WidgetThemeIntent.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline

struct HabitEntry: TimelineEntry {
    let date: Date
    let snapshot: HabitSnapshot
    let config: WidgetThemeIntent
}

struct HabitProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), snapshot: .sample, config: WidgetThemeIntent())
    }

    func snapshot(for configuration: WidgetThemeIntent, in context: Context) async -> HabitEntry {
        let snap = context.isPreview ? .sample : SnapshotStore.read()
        return HabitEntry(date: Date(), snapshot: snap, config: configuration)
    }

    func timeline(for configuration: WidgetThemeIntent, in context: Context) async -> Timeline<HabitEntry> {
        let entry = HabitEntry(date: Date(), snapshot: SnapshotStore.read(), config: configuration)
        // The app reloads timelines on every change; this just refreshes the ring after midnight.
        let nextMidnight = Calendar.current.nextDate(
            after: Date(), matching: DateComponents(hour: 0, minute: 1), matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(nextMidnight))
    }
}

// MARK: - Widget

@main
struct HabitTrackerWidgetBundle: WidgetBundle {
    var body: some Widget { HabitTrackerWidget() }
}

struct HabitTrackerWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "HabitTrackerWidget",
                               intent: WidgetThemeIntent.self,
                               provider: HabitProvider()) { entry in
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
    @Environment(\.colorScheme) private var systemScheme
    let entry: HabitEntry

    private var snap: HabitSnapshot { entry.snapshot }
    private var resolver: WidgetThemeResolver { entry.config.resolver }
    private var scheme: ColorScheme { resolver.forcedColorScheme ?? systemScheme }
    private var primary: Color { resolver.resolvedTextColor(for: scheme) }
    private var secondary: Color { resolver.secondaryTextColor(for: scheme) }
    private var background: LinearGradient { resolver.backgroundGradient(for: scheme) }

    var body: some View {
        switch family {
        case .systemMedium:         mediumView.environment(\.colorScheme, scheme)
        case .accessoryCircular:    accessoryCircular
        case .accessoryRectangular: accessoryRectangular
        case .accessoryInline:      accessoryInline
        default:                    smallView.environment(\.colorScheme, scheme)
        }
    }

    // Home Screen — small: ring + count
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY").font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(secondary)
            Spacer()
            HStack {
                ProgressRing(fraction: snap.fraction, lineWidth: 9, tint: primary) {
                    Text("\(Int(snap.fraction * 100))%")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(primary)
                }
                .frame(width: 58, height: 58)
                Spacer()
            }
            Spacer()
            Text("\(snap.doneCount) of \(snap.total) done")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(secondary)
        }
        .containerBackground(for: .widget) { background }
    }

    // Home Screen — medium: ring + a few habits
    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                ProgressRing(fraction: snap.fraction, lineWidth: 10, tint: primary) {
                    Text("\(snap.doneCount)/\(snap.total)")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(primary)
                }
                .frame(width: 72, height: 72)
                Text("🔥 \(snap.bestStreak)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(secondary)
            }
            VStack(alignment: .leading, spacing: 6) {
                if snap.items.isEmpty {
                    Text("No habits today").font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(secondary)
                } else {
                    ForEach(snap.items.prefix(4)) { item in
                        HStack(spacing: 8) {
                            Text(item.icon).font(.system(size: 14))
                            Text(item.name).font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(primary).lineLimit(1)
                            Spacer(minLength: 2)
                            Button(intent: ToggleHabitIntent(habitID: item.id)) {
                                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(primary.opacity(item.done ? 1 : 0.55))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) { background }
    }

    // Lock Screen — circular gauge (system-tinted; not themed)
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
            ProgressView(value: snap.fraction)
        }
        .containerBackground(.clear, for: .widget)
    }

    // Lock Screen — inline
    private var accessoryInline: some View {
        Text("✅ \(snap.doneCount)/\(snap.total) habits")
            .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Small reusable ring (widget-local)

private struct ProgressRing<Content: View>: View {
    var fraction: Double
    var lineWidth: CGFloat
    var tint: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.28), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, fraction)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            content()
        }
    }
}

#Preview(as: .systemSmall) {
    HabitTrackerWidget()
} timeline: {
    HabitEntry(date: Date(), snapshot: .sample, config: WidgetThemeIntent())
}
