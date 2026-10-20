import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "../components"
import "../services"

// Gear button plus the bar's own settings panel.
//
// The panel is tabbed: one section at a time, so each slider gets the full card
// width. Every control writes straight into the Settings singleton, which
// persists the result and which theme/Theme.qml reads, so the bar re-lays itself
// out live as you drag.
Item {
    id: root

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    // Purely UI state; deliberately not persisted, so the panel opens on Layout.
    property int tab: 0

    readonly property var selectedKinds: Settings.kindsOf(Settings.layoutCompact)

    readonly property var unselectedKinds:
        Settings.moduleKinds.filter(kind => root.selectedKinds.indexOf(kind) === -1)

    // Preview for the notification sliders. notify-send talks to the same
    // org.freedesktop.Notifications service the bar owns, so the toast goes
    // through the real server rather than being faked in the panel.
    readonly property var testNotificationCommand: [
        "notify-send",
        "-a", "Quickshell",
        "-i", "dialog-information",
        "Test notification",
        "Width " + Settings.notificationWidth + " px · text "
            + Settings.notificationTextSize + " px · icon "
            + Settings.notificationIconSize + " px · padding "
            + Settings.notificationPadding + " px.",
    ]

    Process {
        id: testNotifier
        command: root.testNotificationCommand
    }

    // Reorder the collapsed list from a dropped chip: work out where the chip's
    // centre falls among the others, then let Settings splice it in.
    function dropCompact(from, parentX) {
        const others = []
        for (let i = 0; i < compactChips.count; ++i) {
            if (i === from)
                continue
            const chip = compactChips.itemAt(i)
            others.push(chip ? chip.x + chip.width / 2 : 0)
        }

        let insertAt = others.length
        for (let i = 0; i < others.length; ++i) {
            if (parentX < others[i]) {
                insertAt = i
                break
            }
        }

        Settings.moveCompact(from, insertAt)
    }

    Btn {
        id: button

        icon: Icons.cog
        fg: Theme.subtext
        iconSize: Theme.fontSizeLarge
        horizontalPadding: 6
        highlighted: Popups.isOpen("settings")
        tooltip: "Bar settings"
        onClicked: Popups.toggle("settings")
    }

    Popup {
        name: "settings"
        heading: "Bar settings"
        anchorItem: button
        anchorEdges: Edges.Bottom | Edges.Right
        anchorGravity: Edges.Bottom | Edges.Left

        surfaceItem.implicitWidth: 520
        surfaceItem.contentSpacing: 10

        // ── Tab bar ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 3

            Repeater {
                model: ["Layout", "Rows", "Colours", "Popups", "Motion",
                    "Launcher", "Clock", "Wallpaper"]

                delegate: Chip {
                    required property string modelData
                    required property int index

                    Layout.fillWidth: true
                    label: modelData
                    active: root.tab === index
                    onClicked: root.tab = index
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.outline
        }

        // ── Active section ──────────────────────────────────────────────────
        // Hidden ones are skipped by the layout, so the card resizes to fit.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 11
            visible: root.tab === 0

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: "Shown while collapsed · drag to reorder"
                    color: Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        id: compactChips

                        model: root.selectedKinds

                        delegate: Chip {
                            required property string modelData
                            required property int index

                            label: modelData
                            active: true
                            draggable: true
                            onClicked: Settings.setCompact(modelData, false)
                            onDropped: parentX => root.dropCompact(index, parentX)
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.selectedKinds.length === 0
                    text: "Nothing picked — the collapsed island will be empty."
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 4
                    visible: root.unselectedKinds.length > 0

                    Repeater {
                        model: root.unselectedKinds

                        delegate: Chip {
                            required property string modelData

                            label: modelData
                            active: false
                            onClicked: Settings.setCompact(modelData, true)
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 2
                implicitHeight: 1
                color: Theme.outline
            }

            ChoiceRow {
                label: "Workspace icons"
                value: Settings.workspaceIcons
                options: [
                    { value: false, text: "Dots" },
                    { value: true, text: "App icons" },
                ]
                onPicked: value => Settings.workspaceIcons = value
            }

            Text {
                Layout.fillWidth: true
                text: "Show each workspace's number and an app icon for every "
                    + "window on it. Workspaces whose app has no icon still show "
                    + "their number."
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            SettingRow {
                label: "Pill height"
                from: 20
                to: 48
                value: Settings.pillHeight
                onEdited: value => Settings.pillHeight = Math.round(value)
            }

            SettingRow {
                label: "Bar margin"
                from: 0
                to: 20
                value: Settings.barMargin
                onEdited: value => Settings.barMargin = Math.round(value)
            }

            SettingRow {
                label: "Item spacing"
                from: 0
                to: 12
                value: Settings.itemSpacing
                onEdited: value => Settings.itemSpacing = Math.round(value)
            }

            SettingRow {
                label: "Island spacing"
                from: 0
                to: 20
                value: Settings.islandSpacing
                onEdited: value => Settings.islandSpacing = Math.round(value)
            }

            SettingRow {
                label: "Corner radius"
                from: 0
                to: 20
                value: Settings.radius
                onEdited: value => Settings.radius = Math.round(value)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 11
            visible: root.tab === 1

            SettingRow {
                label: "Row height"
                from: 16
                to: 32
                value: Settings.itemHeight
                onEdited: value => Settings.itemHeight = Math.round(value)
            }

            SettingRow {
                label: "Row radius"
                from: 0
                to: 16
                value: Settings.itemRadius
                onEdited: value => Settings.itemRadius = Math.round(value)
            }

            SettingRow {
                label: "Pill padding"
                from: 0
                to: 20
                value: Settings.pillPadding
                onEdited: value => Settings.pillPadding = Math.round(value)
            }

            SettingRow {
                label: "Font size"
                from: 8
                to: 18
                value: Settings.fontSize
                onEdited: value => Settings.fontSize = Math.round(value)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 11
            visible: root.tab === 2

            SettingRow {
                label: "Accent hue"
                suffix: "°"
                from: 0
                to: 360
                value: Settings.accentHue
                onEdited: value => Settings.accentHue = Math.round(value)
            }

            SettingRow {
                label: "Surface hue"
                suffix: "°"
                from: 0
                to: 360
                value: Settings.surfaceHue
                onEdited: value => Settings.surfaceHue = Math.round(value)
            }

            SettingRow {
                label: "Surface lightness"
                suffix: "%"
                from: 0
                to: 30
                value: Settings.surfaceLightness
                onEdited: value => Settings.surfaceLightness = Math.round(value)
            }

            SettingRow {
                label: "Text lightness"
                suffix: "%"
                from: 50
                to: 100
                value: Settings.textLightness
                onEdited: value => Settings.textLightness = Math.round(value)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 11
            visible: root.tab === 3

            SettingRow {
                label: "Width"
                from: 220
                to: 560
                value: Settings.popupWidth
                onEdited: value => Settings.popupWidth = Math.round(value)
            }

            SettingRow {
                label: "Padding"
                from: 4
                to: 24
                value: Settings.popupPadding
                onEdited: value => Settings.popupPadding = Math.round(value)
            }

            SettingRow {
                label: "Corner radius"
                from: 0
                to: 24
                value: Settings.popupRadius
                onEdited: value => Settings.popupRadius = Math.round(value)
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 3
                implicitHeight: 1
                color: Theme.outline
            }

            Text {
                Layout.fillWidth: true
                text: "Notification toasts"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
            }

            SettingRow {
                label: "Width"
                from: 260
                to: 720
                value: Settings.notificationWidth
                onEdited: value => Settings.notificationWidth = Math.round(value)
            }

            SettingRow {
                label: "Padding"
                from: 6
                to: 28
                value: Settings.notificationPadding
                onEdited: value => Settings.notificationPadding = Math.round(value)
            }

            SettingRow {
                label: "Text size"
                from: 9
                to: 24
                value: Settings.notificationTextSize
                onEdited: value => Settings.notificationTextSize = Math.round(value)
            }

            SettingRow {
                label: "Icon size"
                from: 16
                to: 64
                value: Settings.notificationIconSize
                onEdited: value => Settings.notificationIconSize = Math.round(value)
            }

            RowButton {
                Layout.fillWidth: true
                label: "Send test notification"
                detail: "Preview a toast with the size above"
                glyph: Icons.chevronRight
                onClicked: testNotifier.startDetached()
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 2
                text: "Toasts have their own size, so you can make them easier to "
                    + "read without resizing the bar's popup cards."
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 11
            visible: root.tab === 4

            SettingRow {
                label: "Animation"
                suffix: " ms"
                from: 0
                to: 500
                value: Settings.animNormal
                onEdited: value => Settings.animNormal = Math.round(value)
            }

            ChoiceRow {
                label: "Auto-hide"
                value: Settings.autoHide
                options: [
                    { value: true, text: "On" },
                    { value: false, text: "Off" },
                ]
                onPicked: value => Settings.autoHide = value
            }

            SettingRow {
                visible: Settings.autoHide
                label: "Hide after"
                suffix: " s"
                from: 1
                to: 120
                value: Settings.autoCollapse
                onEdited: value => Settings.autoCollapse = Math.round(value)
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 2
                text: "With auto-hide on, the expanded island folds itself away "
                    + "after that many seconds. It always waits while the pointer "
                    + "is on it or one of its popups is showing. With it off, the "
                    + "island only closes when you click the clock."
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 11
            visible: root.tab === 5

            SettingRow {
                label: "Width"
                from: 320
                to: 760
                value: Settings.launcherWidth
                onEdited: value => Settings.launcherWidth = Math.round(value)
            }

            SettingRow {
                label: "Height"
                from: 160
                to: 760
                value: Settings.launcherHeight
                onEdited: value => Settings.launcherHeight = Math.round(value)
            }

            SettingRow {
                label: "Text size"
                from: 8
                to: 24
                value: Settings.launcherFontSize
                onEdited: value => Settings.launcherFontSize = Math.round(value)
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 2
                text: "The launcher keeps a fixed height, so the list doesn't jump "
                    + "around as you type. Row spacing follows the text size. Only "
                    + "the launcher is affected."
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 11
            visible: root.tab === 6

            ChoiceRow {
                label: "Time format"
                value: Settings.clock24Hour
                options: [
                    { value: true, text: "24-hour" },
                    { value: false, text: "AM / PM" },
                ]
                onPicked: value => Settings.clock24Hour = value
            }

            ChoiceRow {
                label: "Seconds"
                value: Settings.clockSeconds
                options: [
                    { value: false, text: "Hide" },
                    { value: true, text: "Show" },
                ]
                onPicked: value => Settings.clockSeconds = value
            }

            ChoiceRow {
                label: "Weekday"
                value: Settings.clockShowDay
                options: [
                    { value: true, text: "Show" },
                    { value: false, text: "Hide" },
                ]
                onPicked: value => Settings.clockShowDay = value
            }

            ChoiceRow {
                label: "Calendar starts on"
                value: Settings.calendarMondayFirst
                options: [
                    { value: true, text: "Monday" },
                    { value: false, text: "Sunday" },
                ]
                onPicked: value => Settings.calendarMondayFirst = value
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 2
                text: "Left click the clock to fold the island away, right click "
                    + "it for the month calendar. It is the only thing that "
                    + "collapses the island."
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 11
            visible: root.tab === 7

            ChoiceRow {
                label: "Scaling"
                value: Settings.wallpaperMode
                options: [
                    { value: "fill", text: "Fill" },
                    { value: "fit", text: "Fit" },
                    { value: "stretch", text: "Stretch" },
                    { value: "tile", text: "Tile" },
                ]
                onPicked: value => Settings.wallpaperMode = value
            }

            Text {
                Layout.fillWidth: true
                text: Settings.wallpaperPath === ""
                    ? "No wallpaper — the compositor's own backdrop colour shows."
                    : "Current: " + Wallpaper.nameFor(Settings.wallpaperPath)
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: "Click a thumbnail to set it on every monitor."
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }

                Chip {
                    label: Wallpaper.scanning ? "Scanning…" : "Rescan"
                    onClicked: Wallpaper.refresh()
                }
            }

            Flickable {
                id: wallpaperFlick

                Layout.fillWidth: true
                Layout.preferredHeight: 250
                contentWidth: width
                contentHeight: wallpaperGrid.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Grid {
                    id: wallpaperGrid

                    width: wallpaperFlick.width
                    columns: 3
                    spacing: 6

                    readonly property real tileWidth:
                        Math.max(1, (width - spacing * (columns - 1)) / columns)

                    Repeater {
                        model: Wallpaper.choices

                        delegate: WallpaperTile {
                            required property var modelData

                            width: wallpaperGrid.tileWidth
                            height: 84
                            label: modelData.name
                            imageSource: modelData.path === ""
                                ? "" : Wallpaper.sourceFor(modelData.path)
                            selected: Settings.wallpaperPath === modelData.path
                            onClicked: Settings.wallpaperPath = modelData.path
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !Wallpaper.scanning && Wallpaper.entries.length === 0
                text: "No images found yet. Put some in ~/Pictures/Wallpapers, "
                    + "then press Rescan."
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: "Images are listed from ~/Pictures/Wallpapers (put your own "
                    + "there), /usr/share/wallpapers and /usr/share/backgrounds. "
                    + "Add more folders in services/Wallpaper.qml."
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }
        }

        // ── Actions ─────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 2
            implicitHeight: 1
            color: Theme.outline
        }

        RowButton {
            Layout.fillWidth: true
            label: "Rearrange bar items"
            detail: "Drag modules to reorder them, then click Done"
            glyph: Icons.chevronRight
            onClicked: {
                Popups.close()
                Island.toggleRearrange()
            }
        }

        RowButton {
            Layout.fillWidth: true
            label: "Reset to defaults"
            onClicked: Settings.reset()
        }

        Text {
            Layout.fillWidth: true
            text: Settings.path
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideMiddle
        }
    }
}
