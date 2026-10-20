import QtQuick
import QtQuick.Layouts
import "../theme"

// One labelled slider row. With the settings panel showing a single section at a
// time these get the full card width, so the slider is long and easy to hit.
Item {
    id: root

    property string label: ""
    property string suffix: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property real step: 1

    signal edited(real value)

    readonly property string valueText: Math.round(root.value) + root.suffix
    readonly property bool hovered: hoverHandler.hovered

    implicitHeight: column.implicitHeight
    Layout.fillWidth: true

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: root.label
                color: root.hovered ? Theme.text : Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            Text {
                text: root.valueText
                color: root.hovered ? Theme.accent : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
        }

        Slider {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            value: root.value
            from: root.from
            to: root.to
            step: root.step
            onMoved: value => root.edited(value)
        }
    }

    HoverHandler { id: hoverHandler }
}
