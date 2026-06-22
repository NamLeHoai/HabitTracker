//
//  ProgressRing.swift
//  HabitTracker
//

import SwiftUI

/// A circular progress ring with arbitrary center content.
struct ProgressRing<Content: View>: View {
    var progress: Double            // 0...1
    var lineWidth: CGFloat = 8
    var trackColor: Color
    var ringColor: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth))
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: progress)
            content()
        }
    }
}

/// A thin progress ring used as the per-habit toggle indicator (conic-style fill).
struct MiniRing: View {
    var progress: Double
    var color: Color
    var trackColor: Color
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            Circle().stroke(trackColor, lineWidth: 4)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.4), value: progress)
        }
        .frame(width: size, height: size)
    }
}
