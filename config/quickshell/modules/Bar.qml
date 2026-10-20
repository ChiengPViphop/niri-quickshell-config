import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"
import "../services"

// One bar per screen.
//
// Idle, all that is on screen is a small pill in the middle showing the
// workspaces and the clock. Clicking it expands to the full bar: launcher,
// workspaces and window title on the left, now-playing beside the clock, and
// the status and session controls on the right. Clicking the empty strip puts
// it away again.
//
// The left and right pills are rendered from an ordered list of module names
// (Settings.layoutLeft / layoutRight) so their contents can be rearranged by
// dragging in rearrange mode.
PanelWindow {
    id: bar

    required property var modelData

    readonly property string outputName: modelData ? modelData.name : ""

    // Where the side pills sit while collapsed: stacked behind the centre pill,
    // in the middle of the screen, so that expanding looks like they fly out
    // from the middle towards the edges.
    readonly property real leftTuckedX: (width - leftIsland.width) / 2
    readonly property real rightGroupWidth: rightIsland.width + Theme.islandSpacing
        + powerIsland.width
    readonly property real rightGroupTuckedX: (width - rightGroupWidth) / 2

    // ─── Module catalogue ────────────────────────────────────────────────────
    // One Component per module that can appear in a reorderable pill.
    Component { id: launcherComponent; Launcher {} }
    Component { id: workspacesComponent; Workspaces {} }
    Component { id: titleComponent; WindowTitle {} }
    Component { id: clockComponent; Clock {} }
    Component { id: mediaComponent; MediaPill {} }
    Component { id: layoutComponent; KeyboardLayout {} }
    Component { id: trayComponent; Tray {} }
    Component { id: volumeComponent; VolumePill {} }
    Component { id: brightnessComponent; BrightnessPill {} }
    Component { id: clipboardComponent; ClipboardPill {} }
    Component { id: networkComponent; NetworkPill {} }
    Component { id: bluetoothComponent; BluetoothPill {} }
    Component { id: batteryComponent; BatteryPill {} }
    Component { id: settingsComponent; SettingsPanel {} }

    function componentFor(kind) {
        switch (kind) {
        case "launcher": return launcherComponent
        case "workspaces": return workspacesComponent
        case "title": return titleComponent
        case "clock": return clockComponent
        case "media": return mediaComponent
        case "layout": return layoutComponent
        case "tray": return trayComponent
        case "volume": return volumeComponent
        case "brightness": return brightnessComponent
        case "clipboard": return clipboardComponent
        case "network": return networkComponent
        case "bluetooth": return bluetoothComponent
        case "battery": return batteryComponent
        case "settings": return settingsComponent
        }
        return null
    }

    function splitKinds(text) {
        if (!text)
            return []
        return text.split(",").map(part => part.trim()).filter(part => part.length > 0)
    }

    // x of a point in `item`'s coordinate space, in bar coordinates. Our
    // hierarchy is flat and untransformed apart from the drag offset, which the
    // dragged slot ignores when it reports.
    function sceneX(item, local) {
        let total = local
        let node = item
        while (node) {
            total += node.x
            node = node.parent
        }
        return total
    }

    // True if any earlier slot is visible, so the first visible module of a pill
    // doesn't get a leading divider.
    function visibleBefore(repeater, index) {
        for (let i = 0; i < index; ++i) {
            const slot = repeater.itemAt(i)
            if (slot && slot.moduleVisible)
                return true
        }
        return false
    }

    function islandInfo(key) {
        switch (key) {
        case "left":
            return {
                key: "left",
                pill: leftIsland,
                repeater: leftRepeater,
                setting: "layoutLeft",
                kinds: bar.splitKinds(Settings.layoutLeft),
            }
        case "centre":
            return {
                key: "centre",
                pill: centreIsland,
                repeater: centreRepeater,
                setting: "layoutCentre",
                kinds: bar.splitKinds(Settings.layoutCentre),
            }
        case "right":
            return {
                key: "right",
                pill: rightIsland,
                repeater: rightRepeater,
                setting: "layoutRight",
                kinds: bar.splitKinds(Settings.layoutRight),
            }
        }
        return null
    }

    function sceneCentre(info, slot) {
        return info.pill.x + slot.x + slot.width / 2
    }

    // Commit a drag: find the pill under the pointer, work out the slot, and
    // rewrite the saved order. Moving to another pill rewrites both lists.
    function drop(sourceKey, kind, index, sceneX) {
        const source = bar.islandInfo(sourceKey)
        if (!source)
            return

        // The nearest pill wins, so dropping in the gap between pills still does
        // something sensible.
        const targets = ["left", "centre", "right"].map(bar.islandInfo)
        let target = targets[0]
        let best = Infinity
        for (const info of targets) {
            const distance = Math.abs(sceneX - (info.pill.x + info.pill.width / 2))
            if (distance < best) {
                best = distance
                target = info
            }
        }

        if (target.key === source.key) {
            // Reorder within one pill.
            const next = source.kinds.slice()
            next.splice(index, 1)

            let insertAt = next.length
            for (let i = 0, seen = 0; i < source.repeater.count; ++i) {
                if (i === index)
                    continue
                const slot = source.repeater.itemAt(i)
                if (slot && sceneX < bar.sceneCentre(source, slot)) {
                    insertAt = seen
                    break
                }
                ++seen
            }

            next.splice(insertAt, 0, kind)
            if (next.join(",") !== source.kinds.join(","))
                Settings[source.setting] = next.join(",")
            return
        }

        // Move to another pill: take it out of the source, put it in the target.
        const sourceKinds = source.kinds.slice()
        sourceKinds.splice(index, 1)

        const targetKinds = target.kinds.slice()
        let insertAt = targetKinds.length
        for (let i = 0; i < target.repeater.count; ++i) {
            const slot = target.repeater.itemAt(i)
            if (slot && sceneX < bar.sceneCentre(target, slot)) {
                insertAt = i
                break
            }
        }
        targetKinds.splice(insertAt, 0, kind)

        Settings[source.setting] = sourceKinds.join(",")
        Settings[target.setting] = targetKinds.join(",")
    }

    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: "transparent"

    // The bar itself must not take keyboard focus, otherwise niri unfocuses
    // the window underneath. Popups are separate windows and grab focus on
    // their own when they open.
    focusable: false
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"

    Item {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: Theme.barHeight

        // Clicking the empty strip beside the island leaves rearrange mode.
        // Collapsing is deliberately *not* wired here: the clock is what folds
        // the island away, so a stray click out here can't do it.
        MouseArea {
            anchors.fill: parent
            enabled: Island.expanded
            onClicked: if (Island.rearranging)
                Island.rearranging = false
        }

        // ── Side pills ──────────────────────────────────────────────────────
        // Declared before the centre pill so they pass *behind* it: tucked in,
        // the centre pill hides them, and they appear to slide out from
        // underneath it as they fly outwards.
        Pill {
            id: leftIsland

            anchors.verticalCenter: parent.verticalCenter
            enabled: Island.expanded

            x: Island.expanded ? Theme.barMargin : bar.leftTuckedX
            opacity: Island.expanded ? 1 : 0
            visible: Island.expanded || opacity > 0

            Behavior on x {
                NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
            }

            Repeater {
                id: leftRepeater

                model: bar.splitKinds(Settings.layoutLeft)

                delegate: BarSlot {
                    required property string modelData
                    required property int index

                    kind: modelData
                    output: bar.outputName
                    source: bar.componentFor(modelData)
                    showSeparator: index > 0 && bar.visibleBefore(leftRepeater, index)
                    onDropped: (kind, sceneX) => bar.drop("left", kind, index, sceneX)
                }
            }
        }

        Pill {
            id: rightIsland

            anchors.verticalCenter: parent.verticalCenter
            enabled: Island.expanded

            // No Behaviour here: it rides along with the session pill beside it
            // so the two move as one group.
            x: powerIsland.x - Theme.islandSpacing - width
            opacity: Island.expanded ? 1 : 0
            visible: Island.expanded || opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
            }

            Repeater {
                id: rightRepeater

                model: bar.splitKinds(Settings.layoutRight)

                delegate: BarSlot {
                    required property string modelData
                    required property int index

                    kind: modelData
                    output: bar.outputName
                    source: bar.componentFor(modelData)
                    showSeparator: index > 0 && bar.visibleBefore(rightRepeater, index)
                    onDropped: (kind, sceneX) => bar.drop("right", kind, index, sceneX)
                }
            }
        }

        Pill {
            id: powerIsland

            anchors.verticalCenter: parent.verticalCenter
            enabled: Island.expanded

            x: Island.expanded ? parent.width - Theme.barMargin - width
                : bar.rightGroupTuckedX + rightIsland.width + Theme.islandSpacing
            opacity: Island.expanded ? 1 : 0
            visible: Island.expanded || opacity > 0

            Behavior on x {
                NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
            }

            PowerPill {}
        }

        // ── The island, and the middle of the full bar ──────────────────────
        // Declared last so it stays on top of the pills flying out from behind.
        Pill {
            id: centreIsland

            // The pill's background is deliberately not a click target: the clock
            // is what folds the island away, so clicking a gap between modules
            // doesn't surprise you by collapsing it.

            // Keeps the island open while the pointer is resting on it. Assigns
            // on creation too, so a reload can't leave a stale "pointer inside".
            HoverHandler {
                Component.onCompleted: Island.pointerInside = hovered
                onHoveredChanged: Island.pointerInside = hovered
            }

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            // Collapsed: whatever is ticked in the settings panel. Deliberately
            // separate from the expanded arrangement, so the island always has
            // something to show.
            Reveal {
                shown: !Island.expanded

                Repeater {
                    id: compactRepeater

                    model: bar.splitKinds(Settings.layoutCompact)

                    delegate: BarSlot {
                        required property string modelData
                        required property int index

                        kind: modelData
                        output: bar.outputName
                        source: bar.componentFor(modelData)
                        showSeparator: index > 0 && bar.visibleBefore(compactRepeater, index)
                    }
                }
            }

            // Expanded: the middle of the full bar, rearranged like the others.
            Reveal {
                shown: Island.expanded

                Repeater {
                    id: centreRepeater

                    model: bar.splitKinds(Settings.layoutCentre)

                    delegate: BarSlot {
                        required property string modelData
                        required property int index

                        kind: modelData
                        output: bar.outputName
                        source: bar.componentFor(modelData)
                        showSeparator: index > 0 && bar.visibleBefore(centreRepeater, index)
                        onDropped: (kind, sceneX) => bar.drop("centre", kind, index, sceneX)
                    }
                }
            }

            // Rearrange mode is finished from here, since the settings popup
            // would cover the bar.
            Btn {
                visible: Island.rearranging
                icon: Icons.check
                label: "Done"
                fg: Theme.accent
                onClicked: Island.rearranging = false
            }
        }

        // Unread-notification dot. Only while the island is collapsed, so a
        // notification that arrived and timed out is not silently forgotten.
        // The hit area is larger than the dot, and clicking acknowledges all of
        // them.
        Item {
            id: notificationBadge

            anchors.right: centreIsland.right
            anchors.top: centreIsland.top
            anchors.rightMargin: -3
            anchors.topMargin: -3
            width: 18
            height: 18
            visible: !Island.expanded && Notifications.hasUnread
            z: 20

            Rectangle {
                anchors.centerIn: parent
                width: 9
                height: 9
                radius: 4.5
                color: Notifications.urgent ? Theme.red : Theme.accent
                border.width: 2
                border.color: Theme.bg
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.markRead()
            }
        }

        // Expanding the island is the user turning to the bar, so that counts
        // as having seen the unread notifications.
        Connections {
            target: Island

            function onExpandedChanged() {
                if (Island.expanded)
                    Notifications.markRead()
            }
        }
    }
}
