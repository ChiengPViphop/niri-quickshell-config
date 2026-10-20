import QtQuick
import QtQuick.Layouts
import "../theme"

// A labelled row of choices shown as chips. Used for settings that are a pick
// from a few options rather than a range, which a slider suits badly.
Item {
    id: root

    property string label: ""
    property var options: []      // [{ value, text }]
    property var value: null

    signal picked(var value)

    implicitHeight: column.implicitHeight
    Layout.fillWidth: true

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 5

        Text {
            Layout.fillWidth: true
            text: root.label
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
        }

        Flow {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: root.options

                delegate: Chip {
                    required property var modelData

                    label: modelData.text
                    active: root.value === modelData.value
                    onClicked: root.picked(modelData.value)
                }
            }
        }
    }
}
