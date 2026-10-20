import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components"
import "../services"

// Screen brightness: scroll to change it, click for the slider. Hidden on
// machines with no backlight, or without brightnessctl.
Item {
    id: root

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    visible: Brightness.available

    Btn {
        id: button

        icon: Icons.brightness
        fg: Theme.subtext
        iconSize: Theme.fontSizeLarge
        horizontalPadding: 6
        highlighted: Popups.isOpen("brightness")
        tooltip: "Brightness " + Brightness.percent + "%"
        onClicked: Popups.toggle("brightness")
        onScrolled: delta => {
            if (delta !== 0)
                Brightness.change(delta > 0 ? 5 : -5)
        }
    }

    Popup {
        name: "brightness"
        heading: "Brightness"
        anchorItem: button
        anchorEdges: Edges.Bottom | Edges.Right
        anchorGravity: Edges.Bottom | Edges.Left

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 10

            Text {
                text: Icons.brightness
                color: Theme.yellow
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge + 1
            }

            Slider {
                Layout.fillWidth: true
                from: 1
                to: 100
                step: 1
                value: Brightness.percent
                onMoved: value => Brightness.set(value)
            }

            Text {
                Layout.preferredWidth: 38
                text: Brightness.percent + "%"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
