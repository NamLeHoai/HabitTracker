//
//  SettingsView.swift
//  HabitTracker
//
//  Data + sync settings: JSON export/import (backup & restore) and the gated iCloud Sync toggle.
//

import SwiftUI
import UniformTypeIdentifiers
import WidgetKit

struct SettingsView: View {
    @Environment(HabitStore.self) private var store
    @Environment(\.theme) private var t
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var exportURL: URL?
    @State private var showImporter = false
    @State private var importedURL: URL?
    @State private var showImportChoice = false
    @State private var iCloudOn = AppGroup.defaults.bool(forKey: "iCloudSyncEnabled")
    @State private var toast: String?

    @State private var widgetBackground = WidgetThemeStore().background
    @State private var widgetAppearance = WidgetThemeStore().appearance
    @State private var widgetTextColor = WidgetThemeStore().textColor

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    if !SharedStore.cloudKitTemporarilyDisabled { syncSection }
                    widgetSection
                    dataSection
                    if let toast {
                        Text(toast).font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(t.acc).padding(.horizontal, 4)
                    }
                }
                .padding(20)
            }
        }
        .background(AmbientBackground())
        .task { prepareExport() }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                importedURL = url
                showImportChoice = true
            }
        }
        .confirmationDialog("Import backup", isPresented: $showImportChoice, titleVisibility: .visible) {
            Button("Merge with current data") { runImport(.merge) }
            Button("Replace all data", role: .destructive) { runImport(.replace) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Merge keeps your current habits and adds/updates from the file. Replace deletes everything first.")
        }
    }

    private var header: some View {
        HStack {
            Text("Settings").font(.system(size: 30, weight: .heavy, design: .rounded))
            Spacer()
            Button("Done") { dismiss() }
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(t.acc)
        }
        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 8)
    }

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("ICLOUD SYNC")
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $iCloudOn) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Sync").font(.system(size: 16, weight: .semibold))
                        Text("Keep habits in sync across your devices")
                            .font(.system(size: 12.5)).foregroundStyle(t.sub)
                    }
                }
                .tint(t.acc)
                .onChange(of: iCloudOn) { _, on in
                    AppGroup.defaults.set(on, forKey: "iCloudSyncEnabled")
                    toast = on ? "Restart the app to start syncing." : "Restart the app to stop syncing."
                }
                Divider().overlay(t.sep)
                Text("Requires signing into iCloud and enabling the iCloud capability for this app. Changes take effect after a restart.")
                    .font(.system(size: 12)).foregroundStyle(t.faint)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 18)
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("DATA")
            VStack(spacing: 0) {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        row("square.and.arrow.up", "Export Data", "Save a JSON backup")
                    }
                } else {
                    row("square.and.arrow.up", "Export Data", "Preparing…").opacity(0.5)
                }
                Divider().overlay(t.sep).padding(.leading, 52)
                Button { showImporter = true } label: {
                    row("square.and.arrow.down", "Import Data", "Restore from a JSON backup")
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .glassCard(cornerRadius: 18)
        }
    }

    // MARK: Widget

    private var widgetResolver: WidgetThemeResolver {
        WidgetThemeResolver(background: widgetBackground, appearance: widgetAppearance, textColor: widgetTextColor)
    }
    private var widgetScheme: ColorScheme { widgetResolver.forcedColorScheme ?? colorScheme }

    private var widgetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("WIDGET")
            VStack(alignment: .leading, spacing: 14) {
                widgetPreview
                Divider().overlay(t.sep)
                Picker("Background", selection: $widgetBackground) {
                    ForEach(WidgetBackgroundStyle.allCases, id: \.self) { Text(name($0)).tag($0) }
                }
                Picker("Appearance", selection: $widgetAppearance) {
                    ForEach(WidgetAppearance.allCases, id: \.self) { Text(name($0)).tag($0) }
                }
                Picker("Text Color", selection: $widgetTextColor) {
                    ForEach(WidgetTextColor.allCases, id: \.self) { Text(name($0)).tag($0) }
                }
                Text("Sets the default for your home-screen widgets. You can still override a single widget by long-pressing it and choosing Edit Widget.")
                    .font(.system(size: 12)).foregroundStyle(t.faint)
            }
            .tint(t.acc)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 18)
        }
        .onChange(of: widgetBackground) { _, v in widgetStore.background = v; reloadWidgets() }
        .onChange(of: widgetAppearance) { _, v in widgetStore.appearance = v; reloadWidgets() }
        .onChange(of: widgetTextColor) { _, v in widgetStore.textColor = v; reloadWidgets() }
    }

    private var widgetPreview: some View {
        let r = widgetResolver, scheme = widgetScheme
        return VStack(alignment: .leading, spacing: 0) {
            Text("TODAY").font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(r.secondaryTextColor(for: scheme))
            Spacer(minLength: 8)
            Text("3 of 5 done").font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(r.resolvedTextColor(for: scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 84)
        .padding(14)
        .background(r.backgroundGradient(for: scheme), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var widgetStore: WidgetThemeStore { WidgetThemeStore() }
    private func reloadWidgets() { WidgetCenter.shared.reloadAllTimelines() }

    private func name(_ b: WidgetBackgroundStyle) -> String {
        switch b {
        case .brand: "Iridescent"; case .ocean: "Ocean"; case .sunset: "Sunset"
        case .forest: "Forest"; case .graphite: "Graphite"; case .mono: "Minimal"
        }
    }
    private func name(_ a: WidgetAppearance) -> String {
        switch a { case .system: "Automatic"; case .light: "Light"; case .dark: "Dark" }
    }
    private func name(_ c: WidgetTextColor) -> String {
        switch c { case .auto: "Automatic"; case .light: "Light"; case .dark: "Dark"; case .accent: "Accent" }
    }

    private func row(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 17, weight: .semibold))
                .foregroundStyle(t.acc).frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(t.text)
                Text(subtitle).font(.system(size: 12.5)).foregroundStyle(t.sub)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(t.faint)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func label(_ s: String) -> some View {
        Text(s).font(.system(size: 13, weight: .bold)).foregroundStyle(t.sub).padding(.leading, 4)
    }

    private func prepareExport() {
        guard let data = store.exportData() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("HabitTracker-Backup.json")
        try? data.write(to: url, options: .atomic)
        exportURL = url
    }

    private func runImport(_ mode: HabitStore.ImportMode) {
        guard let url = importedURL else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { toast = "Couldn’t read that file."; return }
        if store.importData(data, mode: mode) {
            toast = "Import complete."
            prepareExport()
        } else {
            toast = "That file isn’t a valid HabitTracker backup."
        }
    }
}
