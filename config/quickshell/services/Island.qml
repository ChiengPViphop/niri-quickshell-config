pragma Singleton

import QtQuick
import Quickshell
import "."

// Whether the top island is expanded, and the rules that put it back.
//
// A singleton rather than a property on the bar so that every screen's island
// stays in agreement, and so the IPC handler in shell.qml can drive it.
Singleton {
    id: root

    property bool expanded: false

    // Rearrange mode: while on, bar modules can be dragged to reorder them and
    // their normal click behaviour is disabled. Entering it always expands the
    // island, since the side pills are what you are rearranging.
    property bool rearranging: false

    // Set by the bar while the pointer is over the island. Read here rather than
    // in the bar so the auto-collapse rule lives in one place.
    property bool pointerInside: false

    // Hold it open while the pointer is on it, or while one of its popups is
    // showing — collapsing out from under either would be obnoxious.
    readonly property bool holdOpen: root.pointerInside || root.rearranging
        || Popups.open !== ""

    // How long the expanded island stays up when auto-hide is on, before it
    // collapses itself. Zero is treated as "never", which is what auto-hide
    // being off does too.
    readonly property int autoCollapseMs: Settings.autoHide && Settings.autoCollapse > 0
        ? Settings.autoCollapse * 1000 : 0

    function toggle() {
        root.expanded = !root.expanded
    }

    function collapse() {
        root.expanded = false
    }

    function toggleRearrange() {
        root.rearranging = !root.rearranging
        if (root.rearranging)
            root.expanded = true
    }

    Timer {
        id: collapseTimer

        running: root.expanded && !root.holdOpen && root.autoCollapseMs > 0
        interval: Math.max(250, root.autoCollapseMs)
        repeat: false
        onTriggered: root.collapse()
    }
}
