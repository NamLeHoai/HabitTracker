//
//  OnboardingView.swift
//  HabitTracker
//

import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @Environment(\.theme) private var t
    @State private var step = 0

    private struct Step { let icon, title, body, cta: String }
    private let steps = [
        Step(icon: "🌱", title: "Build a better you",
             body: "Track the habits that matter — one small win at a time. Build good ones, quit the bad.",
             cta: "Get Started"),
        Step(icon: "🎯", title: "Beyond checkmarks",
             body: "Set measurable goals like 8 glasses of water or a 30-minute run. Real progress, not just a tick.",
             cta: "Continue"),
        Step(icon: "🔥", title: "Keep the streak alive",
             body: "Watch streaks grow, fill your calendar, and stay motivated with stats and gentle reminders.",
             cta: "Let’s go"),
    ]

    var body: some View {
        let s = steps[step]
        VStack {
            Spacer()
            VStack(spacing: 0) {
                Text(s.icon).font(.system(size: 104))
                Text(s.title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .padding(.top, 36)
                Text(s.body)
                    .font(.system(size: 16))
                    .foregroundStyle(t.sub)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 280)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 34)
            Spacer()

            VStack(spacing: 0) {
                HStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(i == step ? t.acc : t.pill)
                            .frame(width: i == step ? 24 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: step)
                    }
                }
                .padding(.bottom, 26)

                Button {
                    if step < 2 { step += 1 } else { onFinish() }
                } label: {
                    Text(s.cta)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            LinearGradient(colors: [t.acc, Color(hex: "#FFB23E")],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                        .shadow(color: t.acc.opacity(0.4), radius: 11, y: 10)
                }

                Button(action: onFinish) {
                    Text(step < 2 ? "Skip" : " ")
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(t.sub)
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 46)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(t.bg.ignoresSafeArea())
    }
}
