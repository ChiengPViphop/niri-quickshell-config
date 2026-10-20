import QtQuick
import QtQuick.Layouts
import "../theme"

// Full-width selectable row used by the menus and lists inside popups.
Rectangle {
    id: root

    property string icon: ""
    property color iconColor: Theme.subtext
    property string label: ""
    property string detail: ""
    property string glyph: ""
    property color glyphColor: Theme.muted
    property bool highlighted: false
    property bool interactive: true

    signal clicked()

    implicitHeight: detail === "" ? 32 : 42
    radius: Theme.itemRadius
    color: root.highlighted ? Theme.accentSoft
         : (hoverHandler.hovered && root.interactive ? Theme.hoverSoft : "transparent")
    opacity: root.interactive ? 1 : 0.45
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 9
        anchors.rightMargin: 9
        spacing: 9

        Text {
            visible: root.icon !== ""
            text: root.icon
            color: root.iconColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.label
                color: root.highlighted ? Theme.accent : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.detail !== ""
                text: root.detail
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
            }
        }

        Text {
            visible: root.glyph !== ""
            text: root.glyph
            color: root.glyphColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            Layout.alignment: Qt.AlignVCenter
        }
    }

    HoverHandler {
        id: hoverHandler
        enabled: root.interactive
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
