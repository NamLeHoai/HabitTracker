//
//  AchievementViews.swift
//  HabitTracker
//
//  Badge grid cell + the one-time unlock celebration overlay.
//

import SwiftUI

/// A single badge tile: vivid when earned, dimmed/locked otherwise.
struct AchievementBadge: View {
    let achievement: Achievement
    @Environment(\.theme) private var t

    var body: some View {
        VStack(spacing: 6) {
            Text(achievement.icon)
                .font(.system(size: 30))
                .frame(width: 58, height: 58)
                .background(
                    achievement.isEarned ? AnyShapeStyle(Brand.iridescent(t).opacity(0.9))
                                         : AnyShapeStyle(t.pill),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(achievement.isEarned ? .white.opacity(0.3) : t.sep, lineWidth: 1)
                )
                .grayscale(achievement.isEarned ? 0 : 1)
                .opacity(achievement.isEarned ? 1 : 0.5)
            Text(achievement.title)
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundStyle(achievement.isEarned ? t.text : t.faint)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 28, alignment: .top)
        }
    }
}

/// Full-screen celebration shown when a badge is newly unlocked. Tap anywhere to dismiss.
struct AchievementCelebration: View {
    let achievement: Achievement
    var onDismiss: () -> Void
    @Environment(\.theme) private var t
    @State private var pop = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 16) {
                Text("ACHIEVEMENT UNLOCKED")
                    .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.9))
                Text(achievement.icon)
                    .font(.system(size: 88))
                    .scaleEffect(pop ? 1 : 0.4)
                    .rotationEffect(.degrees(pop ? 0 : -25))
                Text(achievement.title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(achievement.detail)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Button(action: onDismiss) {
                    Text("Nice!")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                }
                .buttonStyle(.brand(Brand.iridescent(t)))
                .padding(.top, 8)
            }
            .padding(28)
            .frame(maxWidth: 320)
            .background(Brand.iridescent(t).opacity(0.25), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .glassCard(cornerRadius: 28)
            .padding(.horizontal, 40)
            .scaleEffect(pop ? 1 : 0.85)
            .opacity(pop ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { pop = true }
        }
    }
}
