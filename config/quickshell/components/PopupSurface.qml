import QtQuick
import QtQuick.Layouts
import "../theme"

// Rounded card used as the background for every popup.
Rectangle {
    id: root

    default property alias content: layout.data
    property alias layoutItem: layout
    property string title: ""
    property real padding: Theme.popupPadding
    property real contentSpacing: 8

    // Centre the heading instead of leaving it against the left edge. The
    // calendar asks for this, since everything else in its card is centred.
    property bool centerTitle: false

    implicitWidth: Theme.popupWidth
    implicitHeight: Math.round(layout.implicitHeight + padding * 2)

    radius: Theme.popupRadius
    color: Theme.bg
    border.width: 1
    border.color: Theme.outline

    // Swallow clicks that miss a real control, so they don't reach the
    // popup's dismiss-on-outside-click background. Declared first so the
    // content below it stays on top and keeps receiving input.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onWheel: wheel => wheel.accepted = true
    }

    ColumnLayout {
        id: layout
        // Fills the card rather than just hanging off the top, so content with
        // `Layout.fillHeight` can take up any height the caller set on the card.
        // With the default content-driven height this is the same as before.
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: root.contentSpacing

        Text {
            visible: root.title !== ""
            text: root.title
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.DemiBold
            Layout.fillWidth: true
            horizontalAlignment: root.centerTitle ? Text.AlignHCenter : Text.AlignLeft
        }
    }
}
