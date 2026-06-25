//
//  WidgetThemeTests.swift
//  HabitTrackerTests
//
//  Pure tests for the widget theme resolver (no WidgetKit). The AppEnum wrappers live in the
//  widget target and share these enums' raw values, so they're covered by build + parity here.
//

import Testing
import SwiftUI
@testable import HabitTracker

struct WidgetThemeTests {
    private func resolver(_ b: WidgetBackgroundStyle, _ a: WidgetAppearance,
                          _ tc: WidgetTextColor) -> WidgetThemeResolver {
        WidgetThemeResolver(background: b, appearance: a, textColor: tc)
    }

    @Test func forcedColorSchemeMapping() {
        #expect(resolver(.brand, .system, .auto).forcedColorScheme == nil)
        #expect(resolver(.brand, .light, .auto).forcedColorScheme == .light)
        #expect(resolver(.brand, .dark, .auto).forcedColorScheme == .dark)
    }

    @Test func autoTextPicksContrast() {
        // Dark backgrounds -> white text.
        #expect(resolver(.brand, .system, .auto).resolvedTextColor(for: .light) == .white)
        #expect(resolver(.graphite, .system, .auto).resolvedTextColor(for: .dark) == .white)
        // Mono on a light scheme is a light background -> dark text.
        #expect(resolver(.mono, .light, .auto).resolvedTextColor(for: .light) != .white)
    }

    @Test func explicitTextColorsIgnoreBackground() {
        #expect(resolver(.mono, .system, .light).resolvedTextColor(for: .dark) == .white)
        #expect(resolver(.brand, .system, .dark).resolvedTextColor(for: .dark) != .white)
    }

    @Test func backgroundDarkness() {
        #expect(resolver(.graphite, .system, .auto).backgroundIsDark(for: .light) == true)
        #expect(resolver(.mono, .system, .auto).backgroundIsDark(for: .light) == false)
        #expect(resolver(.mono, .system, .auto).backgroundIsDark(for: .dark) == true)
    }

    @Test func enumsCoverExpectedCases() {
        #expect(WidgetBackgroundStyle.allCases.count == 6)
        #expect(WidgetAppearance.allCases.count == 3)
        #expect(WidgetTextColor.allCases.count == 4)
    }

    @Test func secondaryTextIsDimmedPrimary() {
        let r = resolver(.brand, .system, .light)
        #expect(r.secondaryTextColor(for: .light) == r.resolvedTextColor(for: .light).opacity(0.85))
    }

    // MARK: - WidgetThemeStore (app-group global default)

    /// Isolated UserDefaults suite per test so parallel execution stays safe.
    private func makeStore() -> WidgetThemeStore {
        let name = "test.widget.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return WidgetThemeStore(defaults: d)
    }

    @Test func storeDefaultsReproduceCurrentLook() {
        let s = makeStore()
        #expect(s.background == .brand)
        #expect(s.appearance == .system)
        #expect(s.textColor == .auto)
    }

    @Test func storeRoundTrips() {
        let name = "test.widget.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        WidgetThemeStore(defaults: d).background = .ocean
        WidgetThemeStore(defaults: d).appearance = .dark
        WidgetThemeStore(defaults: d).textColor = .accent
        // Re-read through a fresh instance on the same suite.
        let reread = WidgetThemeStore(defaults: d)
        #expect(reread.background == .ocean)
        #expect(reread.appearance == .dark)
        #expect(reread.textColor == .accent)
    }

    /// Mirrors the intent's merge rule: nil override -> store value; non-nil -> override.
    @Test func overridePrecedenceMerge() {
        let store = makeStore()
        store.background = .forest
        store.appearance = .light
        store.textColor = .dark

        // All nil -> follow the store default.
        #expect((Optional<WidgetBackgroundStyle>.none ?? store.background) == .forest)
        #expect((Optional<WidgetAppearance>.none ?? store.appearance) == .light)
        #expect((Optional<WidgetTextColor>.none ?? store.textColor) == .dark)

        // Non-nil override wins over the store.
        #expect((WidgetBackgroundStyle.sunset as WidgetBackgroundStyle? ?? store.background) == .sunset)
        #expect((WidgetAppearance.dark as WidgetAppearance? ?? store.appearance) == .dark)
        #expect((WidgetTextColor.accent as WidgetTextColor? ?? store.textColor) == .accent)
    }
}
