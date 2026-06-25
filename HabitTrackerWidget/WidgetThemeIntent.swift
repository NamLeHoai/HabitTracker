//
//  WidgetThemeIntent.swift
//  HabitTrackerWidget
//
//  The configuration intent that backs the system "Edit Widget" UI. Each AppEnum wraps a pure
//  enum from Shared/Core/WidgetTheme.swift so the resolver stays unit-testable.
//

import AppIntents
import WidgetKit

enum BackgroundStyleChoice: String, AppEnum {
    case brand, ocean, sunset, forest, graphite, mono

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Background" }
    static var caseDisplayRepresentations: [BackgroundStyleChoice: DisplayRepresentation] {
        [.brand: "Iridescent", .ocean: "Ocean", .sunset: "Sunset",
         .forest: "Forest", .graphite: "Graphite", .mono: "Minimal"]
    }

    var model: WidgetBackgroundStyle { WidgetBackgroundStyle(rawValue: rawValue) ?? .brand }
}

enum AppearanceChoice: String, AppEnum {
    case system, light, dark

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Appearance" }
    static var caseDisplayRepresentations: [AppearanceChoice: DisplayRepresentation] {
        [.system: "Automatic", .light: "Light", .dark: "Dark"]
    }

    var model: WidgetAppearance { WidgetAppearance(rawValue: rawValue) ?? .system }
}

enum TextColorChoice: String, AppEnum {
    case auto, light, dark, accent

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Text Color" }
    static var caseDisplayRepresentations: [TextColorChoice: DisplayRepresentation] {
        [.auto: "Automatic", .light: "Light", .dark: "Dark", .accent: "Accent"]
    }

    var model: WidgetTextColor { WidgetTextColor(rawValue: rawValue) ?? .auto }
}

struct WidgetThemeIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Habit Widget Theme"
    static var description = IntentDescription("Customize this widget, or leave a field unset to follow the app's Widget settings.")

    // Optional: a nil parameter means "follow the app's global Widget setting" (WidgetThemeStore).
    @Parameter(title: "Background") var background: BackgroundStyleChoice?
    @Parameter(title: "Appearance") var appearance: AppearanceChoice?
    @Parameter(title: "Text Color") var textColor: TextColorChoice?

    init() {}

    var resolver: WidgetThemeResolver {
        let store = WidgetThemeStore()
        return WidgetThemeResolver(background: background?.model ?? store.background,
                                   appearance: appearance?.model ?? store.appearance,
                                   textColor: textColor?.model ?? store.textColor)
    }
}
