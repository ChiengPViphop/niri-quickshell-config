import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"

// The workhorse of the bar: a hoverable, clickable item that shows an icon,
// a label, or both, and owns its own tooltip popup.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property string sublabel: ""
    property string tooltip: ""
    property color fg: Theme.subtext
    property color fgHighlighted: Theme.accent
    property bool highlighted: false
    property bool interactive: true
    property int horizontalPadding: 7
    property real iconSize: Theme.fontSizeLarge
    property real labelSize: Theme.fontSize
    property real iconSpacing: 5
    property real maxLabelWidth: 9999

    // Extra visual children (e.g. an IconImage) are laid out next to the label.
    default property alias extraContent: contentRow.data

    readonly property bool hovered: hoverHandler.hovered

    signal clicked()
    signal middleClicked()
    signal secondaryClicked()
    signal scrolled(real delta)

    implicitWidth: Math.round(contentRow.implicitWidth) + horizontalPadding * 2
    implicitHeight: Theme.itemHeight
    opacity: interactive ? 1 : 0.45
    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

    Rectangle {
        anchors.fill: parent
        radius: Theme.itemRadius
        color: root.highlighted ? Theme.accentSoft
             : root.hovered ? Theme.hoverSoft
             : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: root.iconSpacing

        Text {
            visible: root.icon !== ""
            text: root.icon
            color: root.highlighted ? root.fgHighlighted : root.fg
            font.family: Theme.fontFamily
            font.pixelSize: root.iconSize
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            visible: root.label !== ""
            spacing: 0
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: root.label
                color: root.highlighted ? root.fgHighlighted : root.fg
                font.family: Theme.fontFamily
                font.pixelSize: root.labelSize
                font.weight: Theme.fontWeight
                elide: Text.ElideRight
                Layout.maximumWidth: root.maxLabelWidth
            }

            Text {
                visible: root.sublabel !== ""
                text: root.sublabel
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }

    HoverHandler {
        id: hoverHandler
        enabled: root.interactive
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                root.middleClicked()
            else if (mouse.button === Qt.RightButton)
                root.secondaryClicked()
            else
                root.clicked()
        }
        onWheel: wheel => root.scrolled(wheel.angleDelta.y)
    }

    // Tooltip. grabFocus is false so the compositor never dismisses it behind
    // our back and the `visible` binding below stays authoritative.
    PopupWindow {
        id: tooltipPopup
        visible: root.tooltip !== "" && root.hovered
        color: "transparent"
        grabFocus: false
        implicitWidth: tooltipLabel.implicitWidth + 18
        implicitHeight: tooltipLabel.implicitHeight + 10
        anchor {
            item: root
            edges: Edges.Bottom | Edges.Left
            gravity: Edges.Bottom | Edges.Right
        }

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: Theme.bg
            border.width: 1
            border.color: Theme.outline

            Text {
                id: tooltipLabel
                anchors.centerIn: parent
                text: root.tooltip
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }
}
