//
//  WidgetThemeStore.swift
//  HabitTracker (Shared)
//
//  App-group global default for the widget theme, edited from the in-app Settings sheet.
//  The widget's per-instance configuration intent treats its parameters as optional overrides
//  layered on top of this default (nil parameter -> follow the app setting). UserDefaults is
//  injectable so the store stays unit-testable without any SwiftData/WidgetKit dependency.
//

import Foundation

struct WidgetThemeStore {
    private let defaults: UserDefaults
    init(defaults: UserDefaults = AppGroup.defaults) { self.defaults = defaults }

    private enum Key {
        static let background = "widget.bg"
        static let appearance = "widget.appearance"
        static let textColor = "widget.textColor"
    }

    // Defaults reproduce today's look so existing placed widgets don't change.
    var background: WidgetBackgroundStyle {
        get { defaults.string(forKey: Key.background).flatMap(WidgetBackgroundStyle.init) ?? .brand }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Key.background) }
    }
    var appearance: WidgetAppearance {
        get { defaults.string(forKey: Key.appearance).flatMap(WidgetAppearance.init) ?? .system }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Key.appearance) }
    }
    var textColor: WidgetTextColor {
        get { defaults.string(forKey: Key.textColor).flatMap(WidgetTextColor.init) ?? .auto }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Key.textColor) }
    }

    /// Resolver built from the current global values (used by the in-app live preview).
    var resolver: WidgetThemeResolver {
        WidgetThemeResolver(background: background, appearance: appearance, textColor: textColor)
    }
}
