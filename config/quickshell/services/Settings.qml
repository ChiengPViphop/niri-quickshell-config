pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User-adjustable values, edited from the bar's settings panel and persisted to
// settings.json next to shell.qml.
//
// theme/Theme.qml reads these, so a change applies live to the whole bar. The
// file is written 250ms after the last change, so dragging a slider does not
// hammer the disk.
Singleton {
    id: root

    // Every exposed value and its default. Keep the keys in sync with the
    // properties below; the panel is ordered separately.
    readonly property var defaults: ({
        accentHue: 221,
        barMargin: 6,
        pillHeight: 30,
        itemSpacing: 2,
        islandSpacing: 6,
        radius: 10,
        itemHeight: 22,
        itemRadius: 6,
        pillPadding: 8,
        fontSize: 11,
        popupWidth: 300,
        popupPadding: 12,
        popupRadius: 12,
        notificationWidth: 440,
        notificationPadding: 14,
        notificationTextSize: 15,
        notificationIconSize: 36,
        animNormal: 180,
        surfaceHue: 222,
        surfaceLightness: 13,
        textLightness: 92,
        wallpaperPath: "",
        wallpaperMode: "fill",
        launcherWidth: 470,
        launcherHeight: 420,
        launcherFontSize: 12,
        autoCollapse: 15,
        autoHide: true,
        clock24Hour: true,
        clockSeconds: false,
        clockShowDay: true,
        calendarMondayFirst: true,
        workspaceIcons: true,
        layoutLeft: "launcher,workspaces,title",
        layoutCentre: "media,clock",
        layoutRight: "layout,tray,volume,brightness,network,bluetooth,battery,clipboard,settings",
        layoutCompact: "workspaces,clock",
    })

    // Every module that can appear in the bar, in the canonical order used by the
    // collapsed-island picker.
    readonly property var moduleKinds: [
        "launcher", "workspaces", "title", "clock", "media", "layout",
        "tray", "volume", "brightness", "network", "bluetooth", "battery",
        "clipboard", "settings",
    ]

    // ── Layout ───────────────────────────────────────────────────────────────
    property int barMargin: root.defaults.barMargin
    property int pillHeight: root.defaults.pillHeight
    property int itemSpacing: root.defaults.itemSpacing
    property int islandSpacing: root.defaults.islandSpacing
    property int radius: root.defaults.radius

    // ── Rows ─────────────────────────────────────────────────────────────────
    property int itemHeight: root.defaults.itemHeight
    property int itemRadius: root.defaults.itemRadius
    property int pillPadding: root.defaults.pillPadding

    // ── Text ─────────────────────────────────────────────────────────────────
    property int fontSize: root.defaults.fontSize

    // ── Popups ───────────────────────────────────────────────────────────────
    property int popupWidth: root.defaults.popupWidth
    property int popupPadding: root.defaults.popupPadding
    property int popupRadius: root.defaults.popupRadius

    // ── Notification toasts ──────────────────────────────────────────────────
    // Their own size, so they can be made easier to read without making every
    // popup card larger.
    property int notificationWidth: root.defaults.notificationWidth
    property int notificationPadding: root.defaults.notificationPadding
    property int notificationTextSize: root.defaults.notificationTextSize
    property int notificationIconSize: root.defaults.notificationIconSize

    // ── App launcher ─────────────────────────────────────────────────────────
    // Its own size, so it can be a big command palette without making every
    // other popup huge. The height is the whole card, search field included.
    property int launcherWidth: root.defaults.launcherWidth
    property int launcherHeight: root.defaults.launcherHeight
    property int launcherFontSize: root.defaults.launcherFontSize

    // ── Motion ───────────────────────────────────────────────────────────────
    property int animNormal: root.defaults.animNormal

    // Seconds the expanded island stays up before collapsing itself. 0 never
    // collapses.
    property int autoCollapse: root.defaults.autoCollapse

    // Whether the expanded island folds itself away on its own. Off leaves it
    // open until you click the clock (or a keybind collapses it); the delay
    // below only matters while this is on.
    property bool autoHide: root.defaults.autoHide

    // ── Clock and calendar ───────────────────────────────────────────────────
    property bool clock24Hour: root.defaults.clock24Hour
    property bool clockSeconds: root.defaults.clockSeconds
    property bool clockShowDay: root.defaults.clockShowDay
    property bool calendarMondayFirst: root.defaults.calendarMondayFirst

    // ── Workspaces ───────────────────────────────────────────────────────────
    // Show the icon of each workspace's active window instead of the plain
    // dot / index. Workspaces whose app has no resolvable icon fall back to the
    // dot so nothing disappears.
    property bool workspaceIcons: root.defaults.workspaceIcons

    // ── Colour ───────────────────────────────────────────────────────────────
    // Accent hue in degrees. Saturation and lightness are fixed in Theme.qml so
    // the accent keeps its pastel character; 221 is the original #7aa2f7.
    property int accentHue: root.defaults.accentHue

    // Hue of the whole neutral palette, from the bar surface to the text.
    property int surfaceHue: root.defaults.surfaceHue

    // Percentages. 13 reproduces the original #1c1f26 surface; 92 approximates
    // the original #e5e8ef text.
    property int surfaceLightness: root.defaults.surfaceLightness
    property int textLightness: root.defaults.textLightness

    // ── Wallpaper ────────────────────────────────────────────────────────────
    // Absolute path to an image, or empty to leave the compositor's own
    // backdrop showing. The bar draws it on the background layer.
    property string wallpaperPath: root.defaults.wallpaperPath

    // How the image fills the screen: fill, fit, stretch or tile.
    property string wallpaperMode: root.defaults.wallpaperMode

    // ── Item order ───────────────────────────────────────────────────────────
    // Comma-separated module names, edited by dragging in rearrange mode. These
    // describe the expanded bar; the collapsed island always shows its own
    // small workspaces + clock view.
    property string layoutLeft: root.defaults.layoutLeft
    property string layoutCentre: root.defaults.layoutCentre
    property string layoutRight: root.defaults.layoutRight

    // What the island shows while collapsed. The expanded arrangement above is
    // separate, so `workspaces` can be in both without being shown twice.
    property string layoutCompact: root.defaults.layoutCompact

    function kindsOf(list) {
        if (!list)
            return []
        return list.split(",").map(part => part.trim()).filter(part => part.length > 0)
    }

    function compactHas(kind) {
        return root.kindsOf(root.layoutCompact).indexOf(kind) !== -1
    }

    // Ticking appends, so the order you build is the order the pill shows. A new
    // entry goes on the right; drag it in the panel to move it.
    function setCompact(kind, enabled) {
        const list = root.kindsOf(root.layoutCompact).filter(name => name !== kind)
        if (enabled)
            list.push(kind)
        root.layoutCompact = list.join(",")
    }

    // Move an entry within the collapsed list. `insertAt` is the index it takes
    // among the *other* entries, which is what a drop works out.
    function moveCompact(from, insertAt) {
        const list = root.kindsOf(root.layoutCompact)
        if (from < 0 || from >= list.length)
            return

        const moved = list.splice(from, 1)[0]
        list.splice(insertAt, 0, moved)
        root.layoutCompact = list.join(",")
    }

    readonly property string path: Quickshell.shellPath("settings.json")

    // Set once the file has been read (or found to be missing), so the change
    // handlers below don't save while `apply()` is writing the loaded values
    // back out.
    property bool loaded: false

    FileView {
        id: file

        path: root.path
        // A tiny file, read before the bar's windows exist.
        blockLoading: true

        onLoaded: {
            root.apply(file.text())
            root.loaded = true
        }
        onLoadFailed: error => {
            root.apply("")
            root.loaded = true
        }
    }

    // Apply whatever is present; anything missing or malformed keeps its
    // default, so a hand-edited file can list only the values it cares about.
    function apply(text) {
        if (!text || text.trim() === "")
            return

        let data
        try {
            data = JSON.parse(text)
        } catch (error) {
            return
        }

        for (const key in root.defaults) {
            const value = data[key]
            if (typeof value === "number" && isFinite(value))
                root[key] = value
            else if (typeof value === "string")
                root[key] = value
            else if (typeof value === "boolean")
                root[key] = value
        }
    }

    function toObject() {
        const out = {}
        for (const key in root.defaults)
            out[key] = root[key]
        return out
    }

    function save() {
        file.setText(JSON.stringify(root.toObject(), null, 2) + "\n")
    }

    function reset() {
        for (const key in root.defaults)
            root[key] = root.defaults[key]
    }

    Timer {
        id: saveTimer
        interval: 250
        onTriggered: root.save()
    }

    // Fallback in case neither signal is emitted; saving is harmless once the
    // file has been read.
    Component.onCompleted: root.loaded = true

    onAccentHueChanged: if (root.loaded) saveTimer.restart()
    onBarMarginChanged: if (root.loaded) saveTimer.restart()
    onPillHeightChanged: if (root.loaded) saveTimer.restart()
    onItemSpacingChanged: if (root.loaded) saveTimer.restart()
    onIslandSpacingChanged: if (root.loaded) saveTimer.restart()
    onRadiusChanged: if (root.loaded) saveTimer.restart()
    onItemHeightChanged: if (root.loaded) saveTimer.restart()
    onItemRadiusChanged: if (root.loaded) saveTimer.restart()
    onPillPaddingChanged: if (root.loaded) saveTimer.restart()
    onFontSizeChanged: if (root.loaded) saveTimer.restart()
    onPopupWidthChanged: if (root.loaded) saveTimer.restart()
    onPopupPaddingChanged: if (root.loaded) saveTimer.restart()
    onPopupRadiusChanged: if (root.loaded) saveTimer.restart()
    onNotificationWidthChanged: if (root.loaded) saveTimer.restart()
    onNotificationPaddingChanged: if (root.loaded) saveTimer.restart()
    onNotificationTextSizeChanged: if (root.loaded) saveTimer.restart()
    onNotificationIconSizeChanged: if (root.loaded) saveTimer.restart()
    onLauncherWidthChanged: if (root.loaded) saveTimer.restart()
    onLauncherHeightChanged: if (root.loaded) saveTimer.restart()
    onLauncherFontSizeChanged: if (root.loaded) saveTimer.restart()
    onAnimNormalChanged: if (root.loaded) saveTimer.restart()
    onAutoCollapseChanged: if (root.loaded) saveTimer.restart()
    onAutoHideChanged: if (root.loaded) saveTimer.restart()
    onClock24HourChanged: if (root.loaded) saveTimer.restart()
    onClockSecondsChanged: if (root.loaded) saveTimer.restart()
    onClockShowDayChanged: if (root.loaded) saveTimer.restart()
    onCalendarMondayFirstChanged: if (root.loaded) saveTimer.restart()
    onWorkspaceIconsChanged: if (root.loaded) saveTimer.restart()
    onSurfaceHueChanged: if (root.loaded) saveTimer.restart()
    onSurfaceLightnessChanged: if (root.loaded) saveTimer.restart()
    onTextLightnessChanged: if (root.loaded) saveTimer.restart()
    onWallpaperPathChanged: if (root.loaded) saveTimer.restart()
    onWallpaperModeChanged: if (root.loaded) saveTimer.restart()
    onLayoutLeftChanged: if (root.loaded) saveTimer.restart()
    onLayoutCentreChanged: if (root.loaded) saveTimer.restart()
    onLayoutRightChanged: if (root.loaded) saveTimer.restart()
    onLayoutCompactChanged: if (root.loaded) saveTimer.restart()
}
