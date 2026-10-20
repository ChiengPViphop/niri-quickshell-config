import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"

// One module inside a reorderable island.
//
// The module is created from a Component chosen by `kind`, so an island can be
// rendered from an ordered list of names and reordered at runtime.
//
// Everything is positioned by hand rather than with a Layout: a module inside a
// Loader cannot be a direct child of one, which is also why the title's maximum
// width is applied to the Loader instead of via Layout.maximumWidth.
Item {
    id: root

    property string kind: ""
    property string output: ""
    property Component source: null
    property bool showSeparator: false

    // Only used while Island.rearranging.
    property bool dragging: false
    property real dragOffset: 0

    // The pointer's x in bar coordinates at release, so the bar can work out
    // both the slot and which pill it was dropped on.
    signal dropped(string kind, real sceneX)

    readonly property Item module: loader.item

    readonly property real moduleWidth: {
        if (!loader.item)
            return 0
        const width = loader.item.implicitWidth
        return root.kind === "title" ? Math.min(width, 280) : width
    }

    readonly property real moduleHeight: loader.item ? loader.item.implicitHeight : 0

    // Whether this module has anything to show, so an empty tray or a missing
    // battery does not leave a gap.
    //
    // `visible` is an *effective* value in Qt Quick: it also reads false while
    // an ancestor (the collapsed pill) is hidden, and that would stick. So it is
    // only consulted while the island is expanded; reading Island.expanded here
    // also gives the binding a reason to re-evaluate when it expands again.
    readonly property bool moduleVisible: !Island.expanded
        || (loader.item ? loader.item.visible : true)

    implicitWidth: (separator.visible ? separator.width + Theme.itemSpacing : 0) + moduleWidth
    implicitHeight: Math.max(moduleHeight, separator.visible ? separator.height : 0)

    // Collapsed with preferredWidth rather than `visible`, because a zero-width
    // item still counts as visible to the layout and keeps its binding intact.
    Layout.preferredWidth: root.moduleVisible ? root.implicitWidth : 0
    Layout.preferredHeight: root.moduleVisible ? root.implicitHeight : 0
    opacity: root.moduleVisible ? 1 : 0
    enabled: root.moduleVisible
    clip: !root.moduleVisible

    z: root.dragging ? 10 : 0

    // The moving part: the module plus its rearrange box. Kept in a child Item
    // so that the drag area below does not move with it, which would otherwise
    // stop the offset from growing.
    Item {
        id: draggable

        width: root.implicitWidth
        height: root.implicitHeight

        transform: Translate { x: root.dragOffset }

        // Rearrange affordance: a box around every draggable module.
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            visible: Island.rearranging
            radius: Theme.itemRadius
            color: root.dragging ? Theme.accentSoft : "transparent"
            border.width: 1
            border.color: root.dragging ? Theme.accent : Theme.outline
        }

        Rectangle {
            id: separator

            visible: root.showSeparator
            width: 1
            height: 14
            x: 0
            y: Math.round((draggable.height - height) / 2)
            color: Theme.outline
        }

        Loader {
            id: loader

            x: separator.visible ? separator.width + Theme.itemSpacing : 0
            y: Math.round((draggable.height - height) / 2)
            width: root.moduleWidth
            height: root.moduleHeight
            sourceComponent: root.source

            // While rearranging the modules must not react to the pointer at all.
            enabled: !Island.rearranging

            onLoaded: {
                if (item.output !== undefined)
                    item.output = root.output
                item.width = Qt.binding(() => loader.width)
                item.height = Qt.binding(() => loader.height)
            }
        }
    }

    // The drag area: fills the slot and does not move while it is dragged, so
    // the pointer's local position keeps changing. Declared last so it is on top
    // of the module, which is disabled while rearranging anyway.
    MouseArea {
        anchors.fill: parent
        enabled: Island.rearranging
        visible: Island.rearranging
        preventStealing: true
        cursorShape: Qt.OpenHandCursor

        property real pressX: 0

        onPressed: mouse => {
            root.dragging = true
            pressX = mouse.x
            cursorShape = Qt.ClosedHandCursor
        }

        onPositionChanged: mouse => {
            if (pressed)
                root.dragOffset = mouse.x - pressX
        }

        onReleased: mouse => {
            const sceneX = bar.sceneX(root, mouse.x)
            root.dragging = false
            root.dragOffset = 0
            cursorShape = Qt.OpenHandCursor
            root.dropped(root.kind, sceneX)
        }

        onCanceled: {
            root.dragging = false
            root.dragOffset = 0
        }
    }
}
