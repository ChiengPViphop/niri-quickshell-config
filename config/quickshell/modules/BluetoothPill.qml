import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../theme"
import "../components"
import "../services"
import "../components/Util.js" as Util

// Bluetooth adapter state plus a device list. Hidden when the machine has no
// Bluetooth adapter at all.
Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter !== null && adapter.enabled === true

    readonly property var devices: {
        if (adapter === null)
            return []
        const list = Util.toArray(adapter.devices ? adapter.devices.values : [])
        return list.slice().sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1
            const left = a.name || a.deviceName || ""
            const right = b.name || b.deviceName || ""
            return String(left).localeCompare(String(right))
        })
    }

    readonly property var connectedDevice: {
        for (let i = 0; i < devices.length; i++)
            if (devices[i].connected)
                return devices[i]
        return null
    }

    readonly property string summary: {
        if (adapter === null)
            return "No Bluetooth adapter"
        if (!enabled)
            return "Bluetooth off"
        if (connectedDevice !== null)
            return connectedDevice.name || connectedDevice.address
        return "Bluetooth on, not connected"
    }

    visible: adapter !== null
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    Btn {
        id: button

        icon: Icons.bluetooth
        fg: !root.enabled ? Theme.muted
            : root.connectedDevice !== null ? Theme.accent
            : Theme.subtext
        iconSize: Theme.fontSizeLarge
        horizontalPadding: 6
        highlighted: Popups.isOpen("bluetooth")
        tooltip: root.summary
        onClicked: Popups.toggle("bluetooth")
    }

    Popup {
        name: "bluetooth"
        heading: "Bluetooth"
        anchorItem: button
        anchorEdges: Edges.Bottom | Edges.Right
        anchorGravity: Edges.Bottom | Edges.Left

        RowButton {
            Layout.fillWidth: true
            icon: Icons.bluetooth
            iconColor: root.enabled ? Theme.accent : Theme.muted
            label: "Bluetooth"
            detail: root.enabled ? "Enabled" : "Disabled"
            glyph: root.enabled ? Icons.check : ""
            glyphColor: Theme.accent
            onClicked: root.adapter.enabled = !root.adapter.enabled
        }

        RowButton {
            Layout.fillWidth: true
            visible: root.enabled
            icon: Icons.search
            iconColor: root.adapter && root.adapter.discovering ? Theme.accent : Theme.subtext
            label: "Scan for devices"
            detail: root.adapter && root.adapter.discovering
                ? "Scanning…" : "Look for nearby devices"
            glyph: root.adapter && root.adapter.discovering ? Icons.check : ""
            glyphColor: Theme.accent
            onClicked: root.adapter.discovering = !root.adapter.discovering
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.outline
            visible: root.enabled && root.devices.length > 0
        }

        Repeater {
            model: root.enabled ? root.devices : []

            delegate: RowButton {
                required property var modelData

                Layout.fillWidth: true
                icon: Icons.bluetooth
                iconColor: modelData.connected ? Theme.accent : Theme.subtext
                label: modelData.name || modelData.deviceName || modelData.address
                detail: root.describe(modelData)
                glyph: modelData.connected ? Icons.check : ""
                glyphColor: Theme.accent
                highlighted: modelData.connected
                interactive: !modelData.pairing
                onClicked: root.toggle(modelData)
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.devices.length === 0
            text: root.enabled ? "No devices known yet" : "Enable Bluetooth to see devices"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            topPadding: 2
        }
    }

    function describe(device) {
        if (device.pairing)
            return "Pairing…"
        if (device.connected)
            return device.batteryAvailable
                ? "Connected · " + Math.round(device.battery * 100) + "% battery"
                : "Connected"
        if (device.paired)
            return "Paired"
        return device.address
    }

    function toggle(device) {
        if (device.connected)
            device.disconnect()
        else if (device.paired)
            device.connect()
        else
            device.pair()
    }
}
