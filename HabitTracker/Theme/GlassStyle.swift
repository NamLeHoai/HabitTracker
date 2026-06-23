//
//  GlassStyle.swift
//  HabitTracker
//
//  The iOS 26 Liquid Glass design system for the app. Centralizes everything the redesign
//  needs so screens stay declarative and consistent:
//
//  - `AmbientBackground`     — the iridescent, softly-lit backdrop glass refracts against.
//  - `.glassCard(...)`       — frosted card surface (replaces solid `t.card` + shadow).
//  - `.glassChrome(...)`     — small circular glass controls (toolbar buttons, FAB chrome).
//  - `BrandButtonStyle`      — the gradient "Primary Button" with glow + press response.
//  - `GlassButtonStyle`      — neutral frosted pill button for secondary actions.
//  - `Brand.iridescent` etc. — the shared brand gradients used by hero surfaces.
//
//  Glass is a system material, so these helpers mostly add the bright rim, soft shadow,
//  and optional brand tint that make the material read as a deliberate card or control.
//

import SwiftUI

// MARK: - Brand gradients

enum Brand {
    /// The signature purple→pink→teal sweep used on hero cards and the primary button.
    static func iridescent(_ t: ThemeTokens) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#7C5CFF"),
                Color(hex: "#B06BFF"),
                Color(hex: "#FF6FA8"),
                Color(hex: "#16C8B8"),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    /// A two-stop tint built from any habit/brand color, for tinted hero surfaces.
    static func sweep(_ color: Color) -> LinearGradient {
        LinearGradient(colors: [color, color.opacity(0.65)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func primary(_ t: ThemeTokens) -> LinearGradient {
        LinearGradient(colors: [t.acc, Color(hex: "#B06BFF")],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Ambient background

/// The app backdrop: a flat base wash plus a few heavily-blurred color orbs. The orbs give
/// the Liquid Glass material real color to refract and reflect, echoing the design's light
/// leaks. Kept subtle (and dimmer in light mode) so text on glass stays readable.
struct AmbientBackground: View {
    @Environment(\.theme) private var t

    var body: some View {
        ZStack {
            t.bg

            orb(Color(hex: "#7C5CFF"), size: 420, x: -150, y: -260, opacity: t.isDark ? 0.40 : 0.30)
            orb(Color(hex: "#16C8B8"), size: 360, x: 170, y: -120, opacity: t.isDark ? 0.34 : 0.24)
            orb(Color(hex: "#FF6FA8"), size: 380, x: 150, y: 380, opacity: t.isDark ? 0.30 : 0.20)
            orb(Color(hex: "#3B9EFF"), size: 320, x: -160, y: 460, opacity: t.isDark ? 0.28 : 0.18)
        }
        .ignoresSafeArea()
    }

    private func orb(_ color: Color, size: CGFloat, x: CGFloat, y: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 110)
            .opacity(opacity)
            .offset(x: x, y: y)
    }
}

// MARK: - Glass surfaces

private struct GlassCardModifier: ViewModifier {
    @Environment(\.theme) private var t
    var cornerRadius: CGFloat
    var tint: Color?
    var strokeOpacity: Double

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let glass: Glass = tint.map { Glass.regular.tint($0.opacity(t.isDark ? 0.28 : 0.20)) } ?? .regular
        return content
            .glassEffect(glass, in: shape)
            .overlay(shape.stroke(t.glassStroke.opacity(strokeOpacity), lineWidth: 1))
            .shadow(color: t.shadow, radius: 14, y: 9)
    }
}

extension View {
    /// Frosted card surface. Pass `tint:` for a brand-tinted glass (hero cards).
    func glassCard(cornerRadius: CGFloat = 24, tint: Color? = nil, strokeOpacity: Double = 1) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, tint: tint, strokeOpacity: strokeOpacity))
    }

    /// Small circular glass control (theme toggle, back button, menu).
    func glassChrome(diameter: CGFloat = 40) -> some View {
        modifier(GlassChromeModifier(diameter: diameter))
    }
}

private struct GlassChromeModifier: ViewModifier {
    @Environment(\.theme) private var t
    var diameter: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(width: diameter, height: diameter)
            .glassEffect(.regular.interactive(), in: .circle)
            .overlay(Circle().stroke(t.glassStroke, lineWidth: 1))
            .shadow(color: t.shadow, radius: 8, y: 4)
    }
}

// MARK: - Button styles

/// The gradient "Primary Button": iridescent fill, glow, and a tactile press scale.
struct BrandButtonStyle: ButtonStyle {
    @Environment(\.theme) private var t
    var gradient: LinearGradient?
    var cornerRadius: CGFloat = 18

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return configuration.label
            .foregroundStyle(.white)
            .background((gradient ?? Brand.primary(t)), in: shape)
            .overlay(shape.stroke(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: t.acc.opacity(0.45), radius: 16, y: 9)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Neutral frosted pill for secondary actions (uses the system glass material).
struct GlassButtonStyle: ButtonStyle {
    @Environment(\.theme) private var t
    var cornerRadius: CGFloat = 18

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return configuration.label
            .foregroundStyle(t.text)
            .glassEffect(.regular.interactive(), in: shape)
            .overlay(shape.stroke(t.glassStroke, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BrandButtonStyle {
    static var brand: BrandButtonStyle { BrandButtonStyle() }
    static func brand(_ gradient: LinearGradient, cornerRadius: CGFloat = 18) -> BrandButtonStyle {
        BrandButtonStyle(gradient: gradient, cornerRadius: cornerRadius)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static var glassPill: GlassButtonStyle { GlassButtonStyle() }
}
