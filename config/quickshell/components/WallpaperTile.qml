import QtQuick
import "../theme"

// One thumbnail in the settings panel's wallpaper picker.
Item {
    id: root

    property url imageSource: ""
    property string label: ""
    property bool selected: false

    signal clicked()

    implicitWidth: 150
    implicitHeight: 84

    readonly property bool hovered: hoverHandler.hovered

    Rectangle {
        id: card

        anchors.fill: parent
        radius: Theme.itemRadius
        color: Theme.surfaceHi
        border.width: root.selected ? 2 : 1
        border.color: root.selected ? Theme.accent : Theme.outline
        clip: true

        Image {
            anchors.fill: parent
            visible: root.imageSource !== ""
            source: root.imageSource
            sourceSize.width: 320
            sourceSize.height: 180
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
        }

        // Placeholder for the "None" tile, and for an image that fails to load.
        Text {
            anchors.centerIn: parent
            visible: root.imageSource === ""
            text: root.label
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        // Keep the filename readable over busy artwork.
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 20
            visible: root.imageSource !== ""
            color: Qt.rgba(0, 0, 0, 0.55)

            Text {
                anchors {
                    fill: parent
                    leftMargin: 6
                    rightMargin: 6
                }
                text: root.label
                color: "#ffffff"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: Theme.accentSoft
            opacity: root.hovered ? 0.5 : 0
            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        }
    }

    HoverHandler { id: hoverHandler }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
