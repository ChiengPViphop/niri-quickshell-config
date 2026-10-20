import QtQuick
import QtQuick.Layouts
import "../theme"

// A group of island modules that collapses to nothing while `shown` is false
// and grows into place when it becomes true.
//
// This is a RowLayout rather than a plain Item wrapping one child, because
// several modules (WindowTitle, Clock, Sep) set Layout.* on themselves and that
// only has an effect while they are direct children of a Layout.
RowLayout {
    id: root

    property bool shown: true

    // 0 while collapsed, 1 when fully revealed. Animated so the island grows
    // and shrinks smoothly rather than snapping.
    property real reveal: shown ? 1 : 0
    Behavior on reveal {
        NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
    }

    // clip while collapsed: the children still lay themselves out inside this
    // container, they are just not drawn.
    clip: true
    opacity: reveal

    // Also go invisible once fully collapsed — but only then, so the fade-out
    // still animates. This is what lets a popup tell whether its own instance is
    // the visible one (see Popup.qml's anchorUsable).
    visible: shown || reveal > 0

    // Not merely invisible: disabled children must not react to the pointer
    // while they are collapsed away.
    enabled: shown

    spacing: Theme.itemSpacing
    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: implicitWidth * reveal
}
