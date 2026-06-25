//
//  Color+Hex.swift
//  HabitTracker
//

import SwiftUI

extension Color {
    /// Parses "#RRGGBB" or "#RRGGBBAA".
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        let r, g, b, a: Double
        if cleaned.count == 8 {
            r = Double((rgb & 0xFF00_0000) >> 24) / 255
            g = Double((rgb & 0x00FF_0000) >> 16) / 255
            b = Double((rgb & 0x0000_FF00) >> 8) / 255
            a = Double(rgb & 0x0000_00FF) / 255
        } else {
            r = Double((rgb & 0xFF0000) >> 16) / 255
            g = Double((rgb & 0x00FF00) >> 8) / 255
            b = Double(rgb & 0x0000FF) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
