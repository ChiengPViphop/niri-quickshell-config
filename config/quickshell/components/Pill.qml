import QtQuick
import QtQuick.Layouts
import "../theme"

// One "island" of the bar: a rounded, bordered container that lays its
// children out in a row and sizes itself to fit them.
Rectangle {
    id: root

    // Children land inside the pill's row.
    default property alias content: layout.data
    property alias layoutItem: layout
    property real spacing: Theme.itemSpacing
    property real padding: Theme.pillPadding
    property color baseColor: Theme.surface

    // Whether the pill's own background is a click target. Only the island
    // turns this on; elsewhere it is left off so that clicks in a pill's padding
    // fall through to the bar strip behind it.
    property bool clickable: false
    signal clicked()

    implicitWidth: Math.round(layout.implicitWidth + padding * 2)
    implicitHeight: Math.max(Theme.pillHeight, Math.round(layout.implicitHeight + 8))

    radius: Theme.radius
    color: baseColor
    border.width: 1
    border.color: Theme.outline

    // Declared before the contents so the controls stay on top and keep
    // receiving clicks; this only catches the gaps between them.
    MouseArea {
        anchors.fill: parent
        enabled: root.clickable
        acceptedButtons: Qt.LeftButton
        onClicked: root.clicked()
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: root.spacing
    }
}
