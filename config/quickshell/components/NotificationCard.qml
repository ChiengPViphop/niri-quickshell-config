import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../theme"
import "../services"

// One notification toast: app icon, app name, summary and body, and a close
// button.
//
// Clicking anywhere that is not the close button dismisses it. A critical
// notification gets a red border and never times out on its own; a hovered toast
// waits instead, so a long body can still be read.
Rectangle {
    id: root

    required property var notification

    readonly property int padding: Theme.notificationPadding
    readonly property int iconSize: Theme.notificationIconSize
    readonly property string iconSource: Notifications.iconFor(root.notification)
    readonly property bool critical: root.notification !== null
        && root.notification.urgency === NotificationUrgency.Critical
    readonly property int timeoutMs: Notifications.timeoutFor(root.notification)
    readonly property bool hovered: hoverHandler.hovered

    implicitHeight: layout.implicitHeight + root.padding * 2
    radius: Theme.popupRadius
    color: Theme.bg
    border.width: 1
    border.color: root.critical ? Theme.red : Theme.outline

    // Auto-expire, unless the sender asked for no timeout or it is critical.
    // Expiring keeps the notification unread, which is what the dot is for.
    Timer {
        running: root.timeoutMs > 0 && root.notification !== null && !root.hovered
        interval: root.timeoutMs
        onTriggered: root.notification.expire()
    }

    // Declared before the content so it stays underneath: clicks that miss a
    // real control land here and dismiss the toast.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.notification.dismiss()
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Image {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: root.iconSize
                Layout.preferredHeight: root.iconSize
                visible: root.iconSource !== ""
                source: root.iconSource
                sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.notification ? (root.notification.appName || "") : ""
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.notificationTextSizeSmall
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.notification ? root.notification.summary : ""
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.notificationTextSize
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.notification ? root.notification.body : ""
                    color: Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.notificationTextSizeSmall
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }

            Btn {
                Layout.alignment: Qt.AlignTop
                icon: Icons.close
                iconSize: Theme.notificationTextSizeSmall
                horizontalPadding: 4
                tooltip: "Dismiss"
                onClicked: root.notification.dismiss()
            }
        }
    }

    HoverHandler { id: hoverHandler }
}
