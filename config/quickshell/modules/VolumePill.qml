import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components"
import "../services"

// Volume indicator and mixer. Left click opens the slider, right click mutes,
// the wheel adjusts the level. Falls back gracefully when PipeWire is down.
Item {
    id: root

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    Btn {
        id: button

        readonly property bool silent: Audio.muted || Audio.percent === 0

        icon: root.silent ? Icons.volumeOff
            : Audio.percent < 50 ? Icons.volumeLow
            : Icons.volumeHigh
        fg: Audio.muted ? Theme.muted : Theme.subtext
        iconSize: Theme.fontSizeLarge
        horizontalPadding: 6
        highlighted: Popups.isOpen("volume")
        tooltip: !Audio.available ? "No audio output"
            : Audio.muted ? "Muted"
            : "Volume " + Audio.percent + "%"
        onClicked: Popups.toggle("volume")
        onSecondaryClicked: Audio.toggleMute()
        onScrolled: delta => {
            if (delta !== 0)
                Audio.changeVolume(delta > 0 ? 0.05 : -0.05)
        }
    }

    Popup {
        name: "volume"
        heading: "Volume"
        anchorItem: button
        anchorEdges: Edges.Bottom | Edges.Right
        anchorGravity: Edges.Bottom | Edges.Left

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Layout.topMargin: 2

            Btn {
                icon: Audio.muted ? Icons.volumeOff : Icons.volumeHigh
                fg: Audio.muted ? Theme.red : Theme.text
                iconSize: Theme.fontSizeLarge + 1
                horizontalPadding: 5
                tooltip: Audio.muted ? "Unmute" : "Mute"
                onClicked: Audio.toggleMute()
            }

            Slider {
                Layout.fillWidth: true
                from: 0
                to: 1.5
                value: Audio.volume
                onMoved: value => Audio.setVolume(value)
            }

            Text {
                Layout.preferredWidth: 38
                text: Audio.percent + "%"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                horizontalAlignment: Text.AlignRight
            }
        }

        Text {
            Layout.fillWidth: true
            text: Audio.description !== "" ? Audio.description : "No output device"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideRight
        }
    }
}
