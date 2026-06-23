//
//  Theme.swift
//  HabitTracker
//
//  Light/dark token sets, reworked for the iOS 26 Liquid Glass redesign. The palette is
//  now cool and neutral so the system glass material has something to refract, with a
//  purple/teal brand accent and an iridescent gradient used by hero surfaces. Nunito is
//  substituted with the system rounded font (no bundled font files).
//

import SwiftUI

struct ThemeTokens {
    let isDark: Bool
    let bg: Color
    let bg2: Color
    let card: Color
    let text: Color
    let sub: Color
    let faint: Color
    let sep: Color
    let pill: Color
    let acc: Color          // primary brand (purple)
    let acc2: Color         // secondary brand (teal)
    let nav: Color
    let shadow: Color
    let glassStroke: Color   // bright rim on glass surfaces
    let glassHighlight: Color // inner top highlight

    static let light = ThemeTokens(
        isDark: false,
        bg: Color(hex: "#EBE9F2"),
        bg2: Color(hex: "#E3E0EC"),
        card: Color(hex: "#FFFFFF"),
        text: Color(hex: "#1B1A22"),
        sub: Color(hex: "#807C8C"),
        faint: Color(hex: "#B7B3C4"),
        sep: Color(hex: "#1A1430").opacity(0.07),
        pill: Color(hex: "#E6E3EF"),
        acc: Color(hex: "#7C5CFF"),
        acc2: Color(hex: "#16C8B8"),
        nav: Color(hex: "#FFFFFF").opacity(0.55),
        shadow: Color(hex: "#2A2348").opacity(0.13),
        glassStroke: Color(hex: "#FFFFFF").opacity(0.55),
        glassHighlight: Color(hex: "#FFFFFF").opacity(0.65)
    )

    static let dark = ThemeTokens(
        isDark: true,
        bg: Color(hex: "#0E0D14"),
        bg2: Color(hex: "#16141F"),
        card: Color(hex: "#1C1A26"),
        text: Color(hex: "#F2F0F8"),
        sub: Color(hex: "#9A95A8"),
        faint: Color(hex: "#5E5870"),
        sep: Color(hex: "#FFFFFF").opacity(0.09),
        pill: Color(hex: "#26222F"),
        acc: Color(hex: "#9B82FF"),
        acc2: Color(hex: "#2BD4C4"),
        nav: Color(hex: "#1A1622").opacity(0.55),
        shadow: Color(hex: "#000000").opacity(0.45),
        glassStroke: Color(hex: "#FFFFFF").opacity(0.16),
        glassHighlight: Color(hex: "#FFFFFF").opacity(0.22)
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
