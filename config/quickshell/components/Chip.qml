import QtQuick
import "../theme"

// A small selectable pill. Used for the settings panel's tab bar and for picking
// and ordering the collapsed island's modules.
//
// Give it `Layout.fillWidth` to make a row of them share the width evenly (the
// tab bar); leave it off and they size to their label (the module chips).
//
// With `draggable` on, a press that moves is a reorder (emitting `dropped` with
// the pointer's x in the parent's coordinates) and a press that doesn't is a
// click. The hit area is a sibling of the moving part, so it stays put while the
// chip is dragged — otherwise the pointer's local position would travel with the
// chip and the offset would stop growing.
Item {
    id: root

    property string label: ""
    property bool active: false
    property bool draggable: false

    property bool dragging: false
    property real dragOffset: 0

    signal clicked()
    signal dropped(real parentX)

    readonly property bool hovered: hoverHandler.hovered
    readonly property int dragThreshold: 5

    implicitWidth: labelText.implicitWidth + 18
    implicitHeight: 26

    z: root.dragging ? 5 : 0

    Rectangle {
        id: visual

        anchors.fill: parent
        radius: Theme.itemRadius
        color: root.active ? Theme.accentSoft
            : root.hovered ? Theme.hoverSoft
            : "transparent"
        border.width: root.dragging ? 1 : 0
        border.color: Theme.accent
        transform: Translate { x: root.dragOffset }

        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Text {
            id: labelText

            anchors.centerIn: parent
            text: root.label
            color: root.active ? Theme.accent
                : root.hovered ? Theme.text
                : Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: root.active ? Font.DemiBold : Font.Normal

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
    }

    HoverHandler { id: hoverHandler }

    MouseArea {
        id: pointer

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        property real pressX: 0
        property bool moved: false

        onPressed: mouse => {
            pressX = mouse.x
            moved = false
        }

        onPositionChanged: mouse => {
            if (!root.draggable || !pressed)
                return
            const delta = mouse.x - pressX
            if (!moved && Math.abs(delta) < root.dragThreshold)
                return
            moved = true
            root.dragging = true
            root.dragOffset = delta
        }

        onReleased: mouse => {
            if (root.dragging) {
                const parentX = root.x + mouse.x
                root.dragging = false
                root.dragOffset = 0
                root.dropped(parentX)
            } else if (!moved) {
                root.clicked()
            }
            moved = false
        }

        onCanceled: {
            root.dragging = false
            root.dragOffset = 0
            moved = false
        }
    }
}
