import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../theme"
import "../components"
import "../services"
import "../components/Util.js" as Util

// Wi-Fi / Ethernet indicator with a popup that lists nearby Wi-Fi networks.
// Connecting to a secured network we have never seen before asks for the
// password and hands it to nmcli on stdin, so it never shows up in `ps`.
Item {
    id: root

    readonly property var devices: Networking.devices
        ? Util.toArray(Networking.devices.values) : []

    readonly property var wifiDevice: {
        for (let i = 0; i < devices.length; i++)
            if (devices[i].type === DeviceType.Wifi)
                return devices[i]
        return null
    }

    readonly property var wiredDevice: {
        for (let i = 0; i < devices.length; i++)
            if (devices[i].type === DeviceType.Wired)
                return devices[i]
        return null
    }

    readonly property bool wifiOn: Networking.wifiEnabled === true

    readonly property var wifiNetworks: {
        const source = wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : null
        return Util.toArray(source).filter(n => n.name && n.name !== "")
    }

    readonly property var connectedNetwork: {
        for (let i = 0; i < wifiNetworks.length; i++)
            if (wifiNetworks[i].connected)
                return wifiNetworks[i]
        return null
    }

    readonly property bool wiredConnected: wiredDevice !== null && wiredDevice.connected === true

    // Connected and known networks float to the top, then strongest signal.
    readonly property var listedNetworks: {
        const list = wifiNetworks.slice().sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1
            if (a.known !== b.known)
                return a.known ? -1 : 1
            return (b.signalStrength || 0) - (a.signalStrength || 0)
        })
        return list.slice(0, 10)
    }

    readonly property bool online: wiredConnected || connectedNetwork !== null

    readonly property string summary: {
        if (wiredConnected)
            return "Wired connection" + (wiredDevice.address ? " · " + wiredDevice.address : "")
        if (connectedNetwork !== null)
            return connectedNetwork.name
        if (!wifiOn)
            return "Wi-Fi is off"
        return "Wi-Fi on, not connected"
    }

    // Network we are currently asking a password for, if any.
    property var pendingNetwork: null
    property string errorMessage: ""

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    Btn {
        id: button

        icon: root.wiredConnected ? Icons.link
            : root.connectedNetwork !== null ? Icons.wifi
            : root.wifiOn ? Icons.wifi
            : Icons.wifiOff
        fg: root.online ? Theme.subtext : Theme.muted
        iconSize: Theme.fontSizeLarge
        horizontalPadding: 6
        highlighted: Popups.isOpen("network")
        tooltip: root.summary
        onClicked: Popups.toggle("network")
    }

    Popup {
        name: "network"
        heading: "Network"
        anchorItem: button
        anchorEdges: Edges.Bottom | Edges.Right
        anchorGravity: Edges.Bottom | Edges.Left

        RowButton {
            Layout.fillWidth: true
            visible: root.wifiDevice !== null
            icon: root.wifiOn ? Icons.wifi : Icons.wifiOff
            iconColor: root.wifiOn ? Theme.accent : Theme.muted
            label: "Wi-Fi"
            detail: root.wifiOn
                ? (root.connectedNetwork !== null ? root.connectedNetwork.name : "Not connected")
                : "Disabled"
            glyph: root.wifiOn ? Icons.check : ""
            glyphColor: Theme.accent
            onClicked: Networking.wifiEnabled = !root.wifiOn
        }

        RowButton {
            Layout.fillWidth: true
            visible: root.wiredDevice !== null
            icon: Icons.link
            iconColor: root.wiredConnected ? Theme.accent : Theme.subtext
            label: root.wiredDevice ? root.wiredDevice.name : "Ethernet"
            detail: root.wiredConnected ? "Connected" : "Cable unplugged"
            glyph: root.wiredConnected ? Icons.check : ""
            glyphColor: Theme.accent
            interactive: root.wiredConnected
            onClicked: if (root.wiredDevice) root.wiredDevice.disconnect()
        }

        // ── Password prompt ──────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.pendingNetwork !== null
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Password for " + (root.pendingNetwork ? root.pendingNetwork.name : "")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: Theme.itemRadius
                    color: Theme.surfaceHi
                    border.width: 1
                    border.color: passwordField.activeFocus ? Theme.accent : Theme.outline

                    TextInput {
                        id: passwordField
                        anchors.fill: parent
                        anchors.leftMargin: 7
                        anchors.rightMargin: 7
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        echoMode: TextInput.Password
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.bg
                        clip: true
                        onAccepted: root.submitPassword()
                        Keys.onEscapePressed: root.cancelPassword()
                    }

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        visible: passwordField.text === ""
                        text: "Password"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                Btn {
                    label: "Connect"
                    fg: Theme.accent
                    onClicked: root.submitPassword()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.errorMessage !== ""
            text: root.errorMessage
            color: Theme.red
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.outline
            visible: root.listedNetworks.length > 0
        }

        Repeater {
            model: root.listedNetworks

            delegate: RowButton {
                required property var modelData

                Layout.fillWidth: true
                icon: Icons.wifi
                iconColor: modelData.connected ? Theme.accent : Theme.subtext
                label: modelData.name
                detail: root.describe(modelData)
                glyph: root.strength(modelData)
                    + (modelData.security === WifiSecurityType.Open ? "" : "  " + Icons.lock)
                glyphColor: modelData.connected ? Theme.accent : Theme.muted
                highlighted: modelData.connected
                onClicked: root.select(modelData)
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.listedNetworks.length === 0
            text: root.wifiOn ? "Scanning for networks…" : "Turn Wi-Fi on to see networks"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            topPadding: 2
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────
    function describe(network) {
        if (network.connected)
            return "Connected"
        switch (network.state) {
        case ConnectionState.Connecting:
            return "Connecting…"
        case ConnectionState.Disconnecting:
            return "Disconnecting…"
        }
        return network.known ? "Saved network" : "Not saved"
    }

    function strength(network) {
        const value = Math.round(Util.clamp01(network.signalStrength || 0) * 100)
        return value + "%"
    }

    function select(network) {
        if (!network || network.connected)
            return

        root.errorMessage = ""

        if (network.known || network.security === WifiSecurityType.Open) {
            network.connect()
            Popups.close()
            return
        }

        root.pendingNetwork = network
    }

    function submitPassword() {
        const network = root.pendingNetwork
        if (!network)
            return

        connectJob.ssid = network.name
        connectJob.password = passwordField.text
        root.pendingNetwork = null
        passwordField.text = ""
        connectJob.running = true
    }

    function cancelPassword() {
        root.pendingNetwork = null
        passwordField.text = ""
    }

    Process {
        id: connectJob

        property string ssid: ""
        property string password: ""

        command: ["nmcli", "--ask", "device", "wifi", "connect", connectJob.ssid]
        stdinEnabled: true
        running: false

        onStarted: connectJob.write(connectJob.password + "\n")

        onExited: exitCode => {
            if (exitCode !== 0)
                root.errorMessage = "Could not connect to " + connectJob.ssid
        }
    }

    // Ask NetworkManager to rescan whenever the popup is opened.
    Connections {
        target: Popups

        function onOpenChanged() {
            if (Popups.open === "network" && root.wifiDevice)
                root.wifiDevice.scannerEnabled = true
        }
    }
}
