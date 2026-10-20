import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components"
import "../services"

// Clipboard history: click for the list, click an entry to put it back on the
// clipboard. Hidden unless cliphist is installed.
Item {
    id: root

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    visible: Clipboard.available

    Btn {
        id: button

        icon: Icons.clipboard
        fg: Theme.subtext
        iconSize: Theme.fontSizeLarge
        horizontalPadding: 6
        highlighted: Popups.isOpen("clipboard")
        tooltip: Clipboard.entries.length === 0
            ? "Clipboard history"
            : "Clipboard history · " + Clipboard.entries.length + " items"
        onClicked: Popups.toggle("clipboard")
    }

    Popup {
        name: "clipboard"
        heading: "Clipboard"
        anchorItem: button
        anchorEdges: Edges.Bottom | Edges.Right
        anchorGravity: Edges.Bottom | Edges.Left

        Text {
            Layout.fillWidth: true
            visible: Clipboard.entries.length === 0
            text: "Nothing copied yet.\n\nHistory is only kept while "
                + "`wl-paste --watch cliphist store` is running."
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(360,
                Math.max(32, Clipboard.entries.length * 34))
            visible: Clipboard.entries.length > 0
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: Clipboard.entries

            delegate: RowButton {
                required property var modelData

                width: ListView.view.width
                icon: modelData.binary ? Icons.clipboard : ""
                label: modelData.binary ? "binary data" : modelData.text
                onClicked: {
                    Clipboard.copy(modelData.id)
                    Popups.close()
                }
            }
        }

        RowButton {
            Layout.fillWidth: true
            visible: Clipboard.entries.length > 0
            icon: Icons.trash
            label: "Clear history"
            onClicked: Clipboard.wipe()
        }
    }

    // Refresh on open, then keep it up to date while it is showing.
    Connections {
        target: Popups

        function onOpenChanged() {
            if (Popups.isOpen("clipboard"))
                Clipboard.refresh()
        }
    }

    Timer {
        running: Popups.isOpen("clipboard")
        interval: 2500
        repeat: true
        onTriggered: Clipboard.refresh()
    }
}
