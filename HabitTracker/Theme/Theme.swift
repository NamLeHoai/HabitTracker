//
//  Theme.swift
//  HabitTracker
//
//  Light/dark token sets ported from the prototype's `themeVars()` (line 636), plus an
//  @Observable manager that persists the choice. Nunito is substituted with the system
//  rounded font (no bundled font files).
//

import SwiftUI

struct ThemeTokens {
    let bg: Color
    let bg2: Color
    let card: Color
    let text: Color
    let sub: Color
    let faint: Color
    let sep: Color
    let pill: Color
    let acc: Color
    let nav: Color
    let shadow: Color

    static let light = ThemeTokens(
        bg: Color(hex: "#F4EEE6"),
        bg2: Color(hex: "#EDE5D9"),
        card: Color(hex: "#FFFFFF"),
        text: Color(hex: "#1D1A16"),
        sub: Color(hex: "#8C8478"),
        faint: Color(hex: "#BDB4A7"),
        sep: Color(hex: "#281C0C").opacity(0.07),
        pill: Color(hex: "#EBE3D8"),
        acc: Color(hex: "#FF6B5E"),
        nav: Color(hex: "#FFFFFF").opacity(0.92),
        shadow: Color(hex: "#3C2C14").opacity(0.10)
    )

    static let dark = ThemeTokens(
        bg: Color(hex: "#141210"),
        bg2: Color(hex: "#1D1916"),
        card: Color(hex: "#221E19"),
        text: Color(hex: "#F4EFE8"),
        sub: Color(hex: "#9B9389"),
        faint: Color(hex: "#6B6359"),
        sep: Color(hex: "#FFFFFF").opacity(0.08),
        pill: Color(hex: "#2A2521"),
        acc: Color(hex: "#FF7A6B"),
        nav: Color(hex: "#1A1613").opacity(0.92),
        shadow: Color(hex: "#000000").opacity(0.40)
    )
}

@Observable
final class ThemeManager {
    var isDark: Bool {
        didSet { UserDefaults.standard.set(isDark, forKey: "isDark") }
    }

    init() {
        isDark = UserDefaults.standard.bool(forKey: "isDark")
    }

    var tokens: ThemeTokens { isDark ? .dark : .light }

    func toggle() { isDark.toggle() }
}

extension EnvironmentValues {
    @Entry var theme: ThemeTokens = .light
}
