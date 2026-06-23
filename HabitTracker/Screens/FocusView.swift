//
//  FocusView.swift
//  HabitTracker
//
//  Pomodoro timer with presets + ambient toggles (UI state only, no audio).
//

import SwiftUI
import Combine

@Observable
final class FocusTimer {
    var minutes = 25
    var remaining = 25 * 60
    var total = 25 * 60
    var running = false

    @ObservationIgnored private var cancellable: AnyCancellable?

    var progress: Double { total > 0 ? 1 - Double(remaining) / Double(total) : 0 }

    var label: String {
        String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }

    var buttonLabel: String {
        running ? "Pause" : (remaining < total ? "Resume" : "Start Focus")
    }

    func toggle() {
        if running {
            stop()
        } else {
            running = true
            cancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in self?.tick() }
        }
    }

    private func tick() {
        if remaining <= 1 {
            remaining = 0
            stop()
        } else {
            remaining -= 1
        }
    }

    func stop() {
        running = false
        cancellable?.cancel()
        cancellable = nil
    }

    func reset() {
        stop()
        remaining = minutes * 60
        total = minutes * 60
    }

    func setPreset(_ m: Int) {
        stop()
        minutes = m
        remaining = m * 60
        total = m * 60
    }
}

struct FocusView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.theme) private var t
    @State private var timer = FocusTimer()
    @State private var ambient: Set<String> = []

    private let presets = [25, 45, 15, 5]
    private let sounds = [("Rain", "🌧️"), ("Forest", "🌲"), ("Waves", "🌊"), ("Cafe", "☕")]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Focus").font(.system(size: 30, weight: .heavy, design: .rounded))
                Spacer()
                Button { theme.toggle() } label: {
                    Text(theme.isDark ? "☀️" : "🌙").font(.system(size: 17))
                        .glassChrome(diameter: 40)
                }
            }
            .padding(.horizontal, 20).padding(.top, 62).padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ProgressRing(progress: timer.progress, lineWidth: 16,
                                 trackColor: t.pill, ringColor: t.acc) {
                        VStack(spacing: 2) {
                            Text(timer.label)
                                .font(.system(size: 54, weight: .black, design: .rounded))
                                .monospacedDigit()
                            Text("stay focused").font(.system(size: 13.5, weight: .semibold)).foregroundStyle(t.sub)
                        }
                    }
                    .frame(width: 248, height: 248).padding(.top, 18)

                    HStack(spacing: 4) {
                        ForEach(presets, id: \.self) { m in
                            let sel = timer.minutes == m
                            Button { timer.setPreset(m) } label: {
                                Text("\(m)m").font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(sel ? t.acc : t.sub)
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(sel ? t.card : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(t.pill, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .padding(.top, 26)

                    HStack(spacing: 12) {
                        Button { timer.reset() } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20, weight: .semibold)).foregroundStyle(t.sub)
                                .frame(width: 54, height: 54)
                                .glassCard(cornerRadius: 17)
                        }
                        Button { timer.toggle() } label: {
                            Text(timer.buttonLabel)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(timer.running ? t.text : .white)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                                        .fill(timer.running
                                              ? AnyShapeStyle(t.pill)
                                              : AnyShapeStyle(Brand.primary(t)))
                                )
                                .shadow(color: timer.running ? .clear : t.acc.opacity(0.4), radius: 14, y: 9)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 16)

                    Text("AMBIENT SOUND").font(.system(size: 13, weight: .bold)).tracking(0.6)
                        .foregroundStyle(t.sub).frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 26).padding(.bottom, 12).padding(.leading, 4)

                    HStack(spacing: 10) {
                        ForEach(sounds, id: \.0) { name, emoji in
                            let on = ambient.contains(name)
                            Button {
                                if on { ambient.remove(name) } else { ambient.insert(name) }
                            } label: {
                                let chip = VStack(spacing: 6) {
                                    Text(emoji).font(.system(size: 24))
                                    Text(name).font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(on ? t.acc : t.sub)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                if on {
                                    chip
                                        .background(t.acc.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(t.acc, lineWidth: 1.5))
                                } else {
                                    chip.glassCard(cornerRadius: 16)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 120)
            }
        }
        .onDisappear { timer.stop() }
    }
}
