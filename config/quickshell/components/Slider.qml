import QtQuick
import "Util.js" as Util
import "../theme"

// Minimal horizontal slider, used by the volume popup and the settings panel.
Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property color fillColor: Theme.accent

    // Amount a wheel notch moves the value. 0 picks a step from the range.
    property real step: 0

    signal moved(real value)

    readonly property real fraction: Util.clamp01((value - from) / (to - from))
    readonly property bool hovered: hoverHandler.hovered
    readonly property bool engaged: hovered || pointer.pressed
    readonly property real wheelStep: root.step > 0
        ? root.step
        : Math.max(0.01, (root.to - root.from) / 50)

    implicitHeight: 20
    implicitWidth: 160

    function commit(pixels) {
        const ratio = Util.clamp01(pixels / Math.max(1, width))
        moved(from + ratio * (to - from))
    }

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: height / 2
        color: Theme.surfaceHi
        border.width: 1
        border.color: Theme.outline

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: parent.border.width
            width: Math.max(0, (parent.width - parent.border.width * 2) * root.fraction)
            height: parent.height - parent.border.width * 2
            radius: height / 2
            color: root.fillColor
        }
    }

    Rectangle {
        id: handle

        anchors.verticalCenter: parent.verticalCenter
        width: root.engaged ? 15 : 12
        height: width
        radius: width / 2
        color: root.engaged ? Theme.text : Theme.subtext
        border.width: 2
        border.color: Theme.surfaceHi
        x: Util.clamp(root.fraction * parent.width - width / 2, 0, parent.width - width)

        Behavior on width { NumberAnimation { duration: Theme.animFast } }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    HoverHandler { id: hoverHandler }

    MouseArea {
        id: pointer

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: event => root.commit(event.x)
        onPositionChanged: event => {
            if (pressed)
                root.commit(event.x)
        }
        onWheel: wheel => root.moved(Util.clamp(
            root.value + (wheel.angleDelta.y > 0 ? root.wheelStep : -root.wheelStep),
            root.from, root.to))
    }
}
