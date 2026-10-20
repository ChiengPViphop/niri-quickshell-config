import QtQuick
import "../theme"
import "../services"

// niri workspaces for one output. Click a workspace to focus it, scroll over
// the group to move between them.
//
// With `Settings.workspaceIcons` off, the original drawing is used: empty
// workspaces are small dots, occupied ones larger, the active one is a filled
// square with its index, urgent ones turn red.
//
// With it on, every workspace shows its number, followed by one app icon per
// window on it, so a glance says both which workspace it is and what is running
// there. The active workspace is the tinted, outlined tile; urgent ones turn
// red. Workspaces whose apps have no resolvable icon still show their number.
Item {
    id: root

    property string output: ""

    readonly property var spaces: Niri.workspacesFor(output)

    implicitWidth: slotRow.implicitWidth
    implicitHeight: Theme.itemHeight

    Row {
        id: slotRow
        anchors.centerIn: parent
        spacing: 1

        Repeater {
            model: root.spaces

            delegate: Item {
                id: slot
                required property var modelData
                required property int index

                readonly property bool active: modelData.is_active === true
                readonly property bool urgent: modelData.is_urgent === true
                readonly property bool empty: modelData.active_window_id === null
                                             || modelData.active_window_id === undefined
                readonly property string labelText: modelData.name
                    ? modelData.name
                    : String(modelData.idx)

                // App icons of every window on this workspace, when the option
                // is on. The plain dot / index drawing is used otherwise.
                readonly property bool showIcons: Settings.workspaceIcons
                readonly property var windowIcons: slot.showIcons
                    ? Niri.iconsForWorkspace(slot.modelData)
                    : []

                implicitWidth: slot.showIcons ? tile.implicitWidth : 20
                implicitHeight: Theme.itemHeight

                // ── Icons and workspace number ──────────────────────────────
                // One tile per workspace: its number, then an icon for every
                // window on it. The number is shown even when a workspace is
                // empty, so the numbering never has holes in it.
                Rectangle {
                    id: tile

                    anchors.centerIn: parent
                    visible: slot.showIcons
                    implicitWidth: tileRow.implicitWidth + 12
                    implicitHeight: 18
                    radius: Theme.itemRadius
                    color: slot.urgent ? Theme.red
                         : slot.active ? Theme.accentSoft
                         : "transparent"
                    border.width: slot.active ? 1 : 0
                    border.color: Theme.accent

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Row {
                        id: tileRow

                        anchors.centerIn: parent
                        height: 16
                        spacing: 3

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: slot.labelText
                            color: slot.urgent ? Theme.bg
                                 : slot.active ? Theme.accent
                                 : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: slot.active ? Font.DemiBold : Font.Normal
                        }

                        Repeater {
                            model: slot.windowIcons

                            delegate: Image {
                                required property string modelData

                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 14
                                source: modelData
                                sourceSize: Qt.size(28, 28)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                        }
                    }
                }

                // ── Dots and index (option off) ─────────────────────────────
                Rectangle {
                    anchors.centerIn: parent
                    visible: !slot.showIcons
                    width: slot.active ? 20 : (slot.empty ? 7 : 9)
                    height: width
                    radius: slot.active ? Theme.itemRadius : width / 2
                    color: slot.urgent ? Theme.red
                         : slot.active ? Theme.accent
                         : slot.empty ? Theme.outline
                         : Theme.subtext

                    Behavior on width {
                        NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic }
                    }
                    Behavior on radius { NumberAnimation { duration: Theme.animFast } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        visible: slot.active
                        text: slot.labelText
                        color: Theme.bg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Niri.focusWorkspace(slot.modelData.idx)
                }
            }
        }
    }

    // Sits above the delegates so wheel events land here, but accepts no
    // buttons so clicks still reach the individual workspaces.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.angleDelta.y < 0)
                Niri.focusWorkspaceDown()
            else if (wheel.angleDelta.y > 0)
                Niri.focusWorkspaceUp()
        }
    }
}
