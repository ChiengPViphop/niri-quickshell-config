import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "../components"
import "../services"
import "../components/Util.js" as Util

// App launcher: a search field plus the matching .desktop entries. Type to
// filter, Up/Down to move, Return to launch, Escape to dismiss.
Item {
    id: root

    readonly property var allEntries: DesktopEntries.applications
        ? Util.toArray(DesktopEntries.applications.values) : []

    property string query: ""
    property int selectedIndex: 0
    property int maxResults: 50

    readonly property var results: root.computeResults()

    // The launcher's own text scale, independent of the rest of the bar. Its
    // search field, rows and row spacing all follow it.
    readonly property int textSize: Settings.launcherFontSize
    readonly property int resultRowHeight: Math.round(root.textSize * 3.2)

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    function computeResults() {
        const needle = root.query.trim().toLowerCase()
        let entries = root.allEntries.filter(entry => !entry.noDisplay)

        if (needle !== "")
            entries = entries.filter(entry => root.matches(entry, needle))

        entries = entries.slice().sort((a, b) =>
            String(a.name || "").localeCompare(String(b.name || "")))

        return entries.slice(0, root.maxResults)
    }

    function matches(entry, needle) {
        if (String(entry.name || "").toLowerCase().indexOf(needle) !== -1)
            return true
        if (String(entry.genericName || "").toLowerCase().indexOf(needle) !== -1)
            return true

        const keywords = Util.toArray(entry.keywords)
        for (let i = 0; i < keywords.length; i++)
            if (String(keywords[i]).toLowerCase().indexOf(needle) !== -1)
                return true

        return false
    }

    function isOpen() {
        return Popups.isOpen("launcher")
    }

    function toggle() {
        if (isOpen())
            Popups.close()
        else
            Popups.open = "launcher"
    }

    function move(delta) {
        if (results.length === 0)
            return
        root.selectedIndex = (root.selectedIndex + delta + results.length) % results.length
    }

    function launchSelected() {
        root.launch(root.results[root.selectedIndex])
    }

    function launch(entry) {
        if (!entry)
            return

        Popups.close()

        if (entry.runInTerminal)
            Quickshell.execDetached([Config.terminal].concat(Config.terminalArgs).concat(
                ["sh", "-c", Util.cleanExec(entry.execString)]))
        else
            entry.execute()
    }

    // Called whenever the popup opens: clear the previous search and put the
    // cursor in the field, so the first keystroke is a query rather than a
    // click. `Popup` handles visibility on its own; this only runs the bits
    // that are specific to the launcher.
    function sync() {
        if (!Popups.isOpen("launcher"))
            return

        search.text = ""
        root.query = ""
        root.selectedIndex = 0

        // The surface is mapped as part of opening, and the compositor can hand
        // over keyboard focus a moment later. Ask now, then again on the next
        // event-loop turn in case the first request arrived too early.
        search.forceActiveFocus()
        Qt.callLater(() => {
            if (Popups.isOpen("launcher"))
                search.forceActiveFocus()
        })
    }

    onSelectedIndexChanged: {
        if (list.count > 0)
            list.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    }

    onResultsChanged: if (list.count > 0) list.positionViewAtBeginning()

    Btn {
        id: button

        icon: Icons.arch
        fg: Theme.accent
        iconSize: Theme.fontSizeLarge + 3
        horizontalPadding: 6
        highlighted: Popups.isOpen("launcher")
        tooltip: "Applications"
        onClicked: root.toggle()
    }

    Popup {
        id: popup

        name: "launcher"
        anchorItem: button
        anchorEdges: Edges.Bottom | Edges.Left
        anchorGravity: Edges.Bottom | Edges.Right

        // A launcher looks like a command palette: centred on the screen, over a
        // dimmed and blurred backdrop. `anchorItem` is still set, only so the
        // popup lands on the right monitor — and because it is opened from a
        // keybind while the bar may be collapsed, the visibility check is off.
        centered: true
        anchorMustBeVisible: false
        dim: 0.15
        blur: true
        layerNamespace: "quickshell-launcher"

        surfaceItem.implicitWidth: Settings.launcherWidth
        // A fixed height, so the list doesn't resize under the pointer as you
        // type and filter it down.
        surfaceItem.implicitHeight: Settings.launcherHeight

        RowLayout {
            id: searchRow

            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(root.textSize * 2)
            spacing: 8

            Text {
                text: Icons.search
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: root.textSize + 1
                Layout.alignment: Qt.AlignVCenter
            }

            TextInput {
                id: search

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: root.textSize
                selectionColor: Theme.accent
                selectedTextColor: Theme.bg
                clip: true

                onTextChanged: {
                    root.query = text
                    root.selectedIndex = 0
                }
                onAccepted: root.launchSelected()
                Keys.onDownPressed: root.move(1)
                Keys.onUpPressed: root.move(-1)
                Keys.onEscapePressed: Popups.close()
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: search.text === ""
                text: "Search applications"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: root.textSize
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.outline
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: root.results

            delegate: Rectangle {
                id: entryRow

                required property var modelData
                required property int index

                readonly property string iconSource:
                    Quickshell.iconPath(entryRow.modelData.icon, true)

                width: ListView.view.width
                height: root.resultRowHeight
                radius: Theme.itemRadius
                color: entryRow.index === root.selectedIndex ? Theme.accentSoft
                    : rowHover.hovered ? Theme.hoverSoft
                    : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 9

                    Item {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        Layout.alignment: Qt.AlignVCenter

                        Image {
                            anchors.fill: parent
                            source: entryRow.iconSource
                            sourceSize: Qt.size(44, 44)
                            visible: entryRow.iconSource !== ""
                            smooth: true
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: entryRow.iconSource === ""
                            text: Icons.arch
                            color: Theme.subtext
                            font.family: Theme.fontFamily
                            font.pixelSize: root.textSize + 1
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: entryRow.modelData.name
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: root.textSize - 1
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.maximumWidth: Math.round(root.textSize * 12.5)
                        visible: text !== ""
                        text: entryRow.modelData.genericName || ""
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: root.textSize - 2
                        elide: Text.ElideRight
                    }
                }

                HoverHandler {
                    id: rowHover

                    onHoveredChanged: if (hovered) root.selectedIndex = entryRow.index
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launch(entryRow.modelData)
                }
            }
        }
    }

    // Popup.qml watches Popups only for its own visibility. There is no binding
    // on `visible` here, so the launcher has to watch the open state as well to
    // clear and focus the search field every time it is shown.
    Connections {
        target: Popups

        function onOpenChanged() {
            root.sync()
        }
    }

    Component.onCompleted: root.sync()

    // Lets a niri keybind drive the launcher, e.g.
    //   spawn-sh-at-startup "qs ipc call launcher toggle"
    // or from a bind:  spawn-sh "qs ipc call launcher toggle"
    IpcHandler {
        target: "launcher"

        function toggle(): void { root.toggle() }
        function open(): void { Popups.open = "launcher" }
        function close(): void { Popups.close() }
    }
}
