pragma Singleton

import QtQuick
import Quickshell
import "../services"

// Central place for every visual constant. Tweak here, not in the modules.
Singleton {
    id: theme

    // ─── Typography ──────────────────────────────────────────────────────────
    // Nerd Fonts carry both the text glyphs and the icon glyphs, so the whole
    // bar uses a single family. The first installed family wins; install
    // `ttf-jetbrains-mono-nerd` for the nicest result.
    readonly property var _installedFonts: Qt.fontFamilies()

    readonly property string fontFamily: {
        const preferred = [
            "JetBrainsMono Nerd Font",
            "JetBrainsMono Nerd Font Mono",
            "MesloLGS Nerd Font Mono",
            "MesloLGM Nerd Font Mono",
            "FantasqueSansM Nerd Font Mono",
            "JetBrains Mono",
            "monospace",
        ]
        for (let i = 0; i < preferred.length; i++) {
            if (theme._installedFonts.indexOf(preferred[i]) !== -1)
                return preferred[i]
        }
        return "monospace"
    }

    readonly property int fontSizeSmall: Math.max(7, Settings.fontSize - 1)
    readonly property int fontSize: Settings.fontSize
    readonly property int fontSizeLarge: Settings.fontSize + 2
    readonly property int fontWeight: Font.Medium

    // ─── Palette (dark neutral + single accent) ──────────────────────────────
    // The neutrals are one hue at a fixed saturation, with the surfaces at four
    // lightness steps and the text at three. surfaceLightness 13 and
    // textLightness 92 reproduce the original palette (#1c1f26, #e5e8ef, ...).
    readonly property real _hue: Settings.surfaceHue / 360
    readonly property real _surfaceL: Math.max(0, Settings.surfaceLightness / 100)
    readonly property real _textL: Settings.textLightness / 100

    readonly property color bg: Qt.hsla(_hue, 0.15, Math.max(0, _surfaceL - 0.037), 1)
    readonly property color surface: Qt.hsla(_hue, 0.15, _surfaceL, 1)
    readonly property color surfaceHi: Qt.hsla(_hue, 0.15, _surfaceL + 0.051, 1)
    readonly property color outline: Qt.hsla(_hue, 0.15, _surfaceL + 0.082, 1)
    readonly property color text: Qt.hsla(_hue, 0.24, _textL, 1)
    readonly property color subtext: Qt.hsla(_hue, 0.13, Math.max(0.02, _textL - 0.275), 1)
    readonly property color muted: Qt.hsla(_hue, 0.10, Math.max(0.02, _textL - 0.502), 1)
    // Hue is editable from the settings panel; saturation and lightness are
    // fixed so the accent keeps the same pastel character (221° is #7aa2f7).
    readonly property color accent: Qt.hsla(Settings.accentHue / 360, 0.886, 0.724, 1)
    readonly property color green: "#9ece6a"
    readonly property color yellow: "#e0af68"
    readonly property color red: "#f7768e"
    readonly property color purple: "#bb9af7"

    readonly property color accentSoft: Qt.rgba(accent.r, accent.g, accent.b, 0.14)
    readonly property color hoverSoft: Qt.rgba(1, 1, 1, 0.06)

    // ─── Metrics ─────────────────────────────────────────────────────────────
    // Editable from the settings panel.
    readonly property int barMargin: Settings.barMargin
    readonly property int pillHeight: Settings.pillHeight
    readonly property int barHeight: pillHeight + barMargin * 2
    readonly property int radius: Settings.radius
    readonly property int itemSpacing: Settings.itemSpacing
    readonly property int islandSpacing: Settings.islandSpacing
    readonly property int popupRadius: Settings.popupRadius
    readonly property int popupPadding: Settings.popupPadding
    readonly property int popupWidth: Settings.popupWidth

    // Notification toasts are sized separately from the bar's popups, so they
    // can be made easier to read without changing every card.
    readonly property int notificationWidth: Settings.notificationWidth
    readonly property int notificationPadding: Settings.notificationPadding
    readonly property int notificationTextSize: Settings.notificationTextSize
    readonly property int notificationTextSizeSmall:
        Math.max(7, Settings.notificationTextSize - 1)
    readonly property int notificationIconSize: Settings.notificationIconSize

    // Row internals, also editable.
    readonly property int itemHeight: Settings.itemHeight
    readonly property int itemRadius: Settings.itemRadius
    readonly property int pillPadding: Settings.pillPadding

    // ─── Motion ──────────────────────────────────────────────────────────────
    readonly property int animFast: 110
    readonly property int animNormal: Settings.animNormal
}
