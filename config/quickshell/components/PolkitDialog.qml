import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import "../theme"
import "../services"

// The Polkit authentication dialog.
//
// One PolkitAgent lives here for the whole shell. It registers with polkitd as
// soon as the shell starts, so applications that need privileged access can ask
// for a password even when they were launched outside the bar.
//
// A layer-shell surface rather than a PopupWindow, for the same reason as
// components/Popup.qml: a layer surface can request exclusive keyboard focus in
// its own right, which is what makes the password field typable on niri.
//
// The request itself is handled by Quickshell.Services.Polkit, including the PAM
// conversation. This component only draws it. Nothing is written to disk or to
// the log; the submitted text goes straight to AuthFlow.submit() and the field is
// cleared.
PanelWindow {
    id: root

    readonly property var flow: agent.flow
    readonly property var identities: root.flow ? root.flow.identities : []
    readonly property bool awaitingInput: root.flow !== null && root.flow.isResponseRequired
    readonly property bool canSubmit: root.awaitingInput

    readonly property string iconSource: root.flow && root.flow.iconName !== ""
        ? Quickshell.iconPath(root.flow.iconName, true) : ""
    readonly property string message: root.flow && root.flow.message !== ""
        ? root.flow.message : "Authentication is required"

    // Width follows the popup cards but is a little wider, since this is a
    // modal dialog with a message, an optional identity picker and a password.
    readonly property int cardWidth: Math.max(360, Theme.popupWidth + 120)

    // Show on the output whose workspace is focused. A polkit request almost
    // always comes from the window the user is looking at; if niri is not
    // connected yet, fall back to the first screen.
    readonly property var focusedWorkspace: {
        const workspaces = Niri.workspaces || []
        for (let i = 0; i < workspaces.length; ++i) {
            if (workspaces[i].is_focused)
                return workspaces[i]
        }
        return null
    }

    readonly property var targetScreen: {
        const screens = Quickshell.screens || []
        const output = root.focusedWorkspace ? root.focusedWorkspace.output : ""
        for (let i = 0; i < screens.length; ++i) {
            if (screens[i].name === output)
                return screens[i]
        }
        return screens.length > 0 ? screens[0] : null
    }

    PolkitAgent {
        id: agent

        onIsRegisteredChanged: console.log("Polkit agent registered:", agent.isRegistered)
    }

    // The request is asynchronous: polkitd may not have started the PAM
    // conversation yet when the window first maps. Ask for focus now and again
    // on the next event-loop turn, which is what the launcher does.
    function focusPrompt() {
        if (!root.awaitingInput || !password)
            return
        password.text = ""
        password.forceActiveFocus()
        Qt.callLater(() => {
            if (root.visible && root.awaitingInput && password)
                password.forceActiveFocus()
        })
    }

    function submit() {
        if (!root.flow || !root.awaitingInput)
            return
        root.flow.submit(password.text)
        password.text = ""
    }

    function cancel() {
        if (root.flow)
            root.flow.cancelAuthenticationRequest()
    }

    screen: root.targetScreen
    visible: agent.isActive

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // -1 keeps the compositor from moving the overlay out of the bar's exclusive
    // zone, exactly as Popup.qml does.
    exclusiveZone: -1
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-polkit"

    // Blur what is behind the dialog, like the launcher. niri's matching layer
    // rule lives in ~/.config/niri/appearance.kdl.
    BackgroundEffect.blurRegion: blurRegion

    Region {
        id: blurRegion
        item: background
    }

    Rectangle {
        id: background

        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.42)
    }

    // Swallow clicks outside the card. Unlike the bar's popups, a stray click
    // must not cancel a password prompt: that is what the Cancel button and
    // Escape are for.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onWheel: wheel => wheel.accepted = true
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible && root.flow !== null
        onActivated: root.cancel()
    }

    Connections {
        target: agent

        function onFlowChanged() {
            root.focusPrompt()
        }

        function onIsActiveChanged() {
            if (agent.isActive)
                root.focusPrompt()
            else if (password)
                password.text = ""
        }
    }

    Connections {
        target: root.flow

        function onIsResponseRequiredChanged() {
            root.focusPrompt()
        }

        function onFailedChanged() {
            if (root.flow && root.flow.failed) {
                password.text = ""
                root.focusPrompt()
            }
        }
    }

    onVisibleChanged: {
        if (root.visible)
            root.focusPrompt()
        else if (password)
            password.text = ""
    }

    PopupSurface {
        id: card

        anchors.centerIn: parent
        implicitWidth: root.cardWidth
        padding: 18
        contentSpacing: 12
        title: "Authentication required"

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 44
                implicitHeight: 44
                radius: 22
                color: Theme.accentSoft

                Text {
                    anchors.centerIn: parent
                    visible: root.iconSource === ""
                    text: Icons.lock
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLarge + 4
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 10
                    visible: root.iconSource !== ""
                    source: root.iconSource
                    sourceSize: Qt.size(48, 48)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: root.message
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.flow ? root.flow.actionId : ""
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.max(7, Theme.fontSizeSmall - 1)
                    elide: Text.ElideRight
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.flow ? root.flow.supplementaryMessage : ""
            color: root.flow && root.flow.supplementaryIsError ? Theme.red : Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            wrapMode: Text.WordWrap
        }

        Text {
            Layout.fillWidth: true
            visible: root.flow !== null && root.flow.failed
                && root.flow.supplementaryMessage === ""
            text: "Authentication failed. Try again."
            color: Theme.red
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            wrapMode: Text.WordWrap
        }

        // Some actions allow more than one user or group to authenticate. The
        // default identity is the first one; picking another restarts the PAM
        // conversation, as AuthFlow documents.
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.identities.length > 1

            Repeater {
                model: root.identities

                delegate: Chip {
                    required property var modelData

                    label: modelData.isGroup
                        ? modelData.string + " (group)"
                        : (modelData.displayName || modelData.string)
                    active: root.flow !== null
                        && root.flow.selectedIdentity === modelData
                    onClicked: {
                        if (root.flow)
                            root.flow.selectedIdentity = modelData
                        root.focusPrompt()
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: root.awaitingInput

            Text {
                Layout.fillWidth: true
                text: root.flow && root.flow.inputPrompt !== ""
                    ? root.flow.inputPrompt : "Password"
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: Theme.itemRadius
                color: Theme.surfaceHi
                border.width: 1
                border.color: password.activeFocus ? Theme.accent : Theme.outline

                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                TextInput {
                    id: password

                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.bg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    echoMode: root.flow && root.flow.responseVisible
                        ? TextInput.Normal : TextInput.Password
                    focus: true
                    clip: true

                    onAccepted: root.submit()
                    Keys.onEscapePressed: root.cancel()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                visible: root.flow !== null && !root.awaitingInput
                    && !root.flow.isCompleted
                text: "Waiting for authentication…"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }

            Item {
                Layout.fillWidth: true
            }

            Btn {
                label: "Cancel"
                horizontalPadding: 12
                tooltip: "Cancel authentication"
                onClicked: root.cancel()
            }

            Btn {
                label: "Authenticate"
                fg: Theme.accent
                highlighted: root.canSubmit
                interactive: root.canSubmit
                horizontalPadding: 12
                tooltip: "Submit the password"
                onClicked: root.submit()
            }
        }
    }
}
