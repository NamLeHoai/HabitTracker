//
//  WidgetTheme.swift
//  HabitTracker (Shared)
//
//  Pure model + resolver for the user-configurable widget appearance. No WidgetKit/AppIntents
//  here so it's unit-testable; the widget wraps these enums in AppEnums for the "Edit Widget" UI.
//

import SwiftUI

enum WidgetBackgroundStyle: String, CaseIterable, Sendable {
    case brand          // the original 3-stop iridescent gradient (default)
    case ocean
    case sunset
    case forest
    case graphite       // near-solid dark
    case mono           // adapts to appearance (light/dark), minimal
}

enum WidgetAppearance: String, CaseIterable, Sendable {
    case system, light, dark
}

enum WidgetTextColor: String, CaseIterable, Sendable {
    case auto           // contrast-picked from the background
    case light, dark, accent
}

/// Pure resolver: theme choices -> concrete colors/gradients. No WidgetKit dependency.
struct WidgetThemeResolver {
    var background: WidgetBackgroundStyle
    var appearance: WidgetAppearance
    var textColor: WidgetTextColor

    /// The brand accent used by the `.accent` text option.
    static let accentHex = "#7C5CFF"
    private static let darkInk = "#1B1A22"

    /// nil = let the system decide; otherwise force this scheme.
    var forcedColorScheme: ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    /// Whether the resolved background reads as dark (drives `.auto` text contrast).
    func backgroundIsDark(for scheme: ColorScheme) -> Bool {
        switch background {
        case .brand, .ocean, .sunset, .forest, .graphite: return true
        case .mono: return scheme == .dark
        }
    }

    func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        let stops: [Color]
        switch background {
        case .brand:    stops = [Color(hex: "#7C5CFF"), Color(hex: "#B06BFF"), Color(hex: "#16C8B8")]
        case .ocean:    stops = [Color(hex: "#2E6BFF"), Color(hex: "#1FB6C8"), Color(hex: "#16C88E")]
        case .sunset:   stops = [Color(hex: "#FF6B5E"), Color(hex: "#FF9D57"), Color(hex: "#FFB23E")]
        case .forest:   stops = [Color(hex: "#2E8B57"), Color(hex: "#34C77B"), Color(hex: "#1FC6B8")]
        case .graphite: stops = [Color(hex: "#2A2533"), Color(hex: "#1C1A26"), Color(hex: "#15131C")]
        case .mono:
            stops = scheme == .dark
                ? [Color(hex: "#1C1A26"), Color(hex: "#15131C")]
                : [Color(hex: "#FFFFFF"), Color(hex: "#ECEAF2")]
        }
        return LinearGradient(colors: stops, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    func resolvedTextColor(for scheme: ColorScheme) -> Color {
        switch textColor {
        case .light:  return .white
        case .dark:   return Color(hex: Self.darkInk)
        case .accent: return Color(hex: Self.accentHex)
        case .auto:   return backgroundIsDark(for: scheme) ? .white : Color(hex: Self.darkInk)
        }
    }

    func secondaryTextColor(for scheme: ColorScheme) -> Color {
        resolvedTextColor(for: scheme).opacity(0.85)
    }
}
