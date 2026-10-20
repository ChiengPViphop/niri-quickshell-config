import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// Toasts for incoming notifications, at the top centre of the screen.
//
// A tight layer surface rather than a full-screen overlay: only the cards are on
// it, so it cannot swallow clicks meant for the window below. With no horizontal
// anchor the compositor centres the surface itself, which is the placement the
// bar's centred popups have to fake by measuring the screen.
PanelWindow {
    id: root

    readonly property int toastWidth: Theme.notificationWidth

    anchors.top: true
    margins.top: Theme.barHeight + 8

    // The cards are all the same width, so the surface is too. The height
    // follows the column, and the window is hidden entirely when there is
    // nothing to show.
    implicitWidth: root.toastWidth
    implicitHeight: column.implicitHeight
    visible: Notifications.count > 0

    color: "transparent"
    exclusiveZone: -1
    focusable: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-notifications"

    Column {
        id: column

        spacing: 8

        Repeater {
            model: Notifications.values

            delegate: NotificationCard {
                required property var modelData

                notification: modelData
                width: root.toastWidth
            }
        }
    }
}
