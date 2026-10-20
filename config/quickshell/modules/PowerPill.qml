import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components"
import "../services"

// The far right island: lock, log out, suspend, reboot, power off.
Item {
    id: root

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    Btn {
        id: button

        icon: Icons.power
        fg: Theme.red
        iconSize: Theme.fontSizeLarge
        horizontalPadding: 6
        highlighted: Popups.isOpen("session")
        tooltip: "Session"
        onClicked: Popups.toggle("session")
    }

    Popup {
        name: "session"
        heading: "Session"
        anchorItem: button
        anchorEdges: Edges.Bottom | Edges.Right
        anchorGravity: Edges.Bottom | Edges.Left

        Repeater {
            model: [
                { icon: Icons.lock, label: "Lock", detail: "Lock this session", action: "lock" },
                { icon: Icons.logout, label: "Log out", detail: "Leave the niri session", action: "logout" },
                { icon: Icons.suspend, label: "Suspend", detail: "Sleep until woken", action: "suspend" },
                { icon: Icons.reboot, label: "Reboot", detail: "Restart the computer", action: "reboot" },
                { icon: Icons.power, label: "Power off", detail: "Shut the computer down", action: "poweroff" },
            ]

            delegate: RowButton {
                required property var modelData

                Layout.fillWidth: true
                icon: modelData.icon
                iconColor: modelData.action === "poweroff" ? Theme.red : Theme.subtext
                label: modelData.label
                detail: modelData.detail
                onClicked: root.run(modelData.action)
            }
        }
    }

    function run(action) {
        Popups.close()

        switch (action) {
        case "lock":
            Quickshell.execDetached(Config.lockCommand)
            break
        case "logout":
            Niri.runAction(["quit", "--skip-confirmation"])
            break
        case "suspend":
            Quickshell.execDetached(["systemctl", "suspend"])
            break
        case "reboot":
            Quickshell.execDetached(["systemctl", "reboot"])
            break
        case "poweroff":
            Quickshell.execDetached(["systemctl", "poweroff"])
            break
        }
    }
}
