pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history, backed by cliphist (and wl-copy to put an entry back).
//
// cliphist only keeps what it is fed, so something has to run
//   wl-paste --watch cliphist store
// from session start — see the README. Without it the list simply stays empty.
//
// `cliphist list` prints "<id>\t<preview>" per entry, newest first. The preview
// is display only; the entry itself is pulled back with `cliphist decode <id>`,
// which is why the id is the only thing that crosses the command line.
Singleton {
    id: root

    readonly property string listTool: "cliphist"
    readonly property string copyTool: "wl-copy"

    property bool available: false
    property var entries: []

    // How many entries the popup can show.
    property int limit: 50

    function refresh() {
        if (!lister.running)
            lister.running = true
    }

    function collect(line) {
        if (!line)
            return

        const tab = line.indexOf("\t")
        if (tab < 0)
            return

        const id = parseInt(line.substring(0, tab), 10)
        if (isNaN(id))
            return

        const preview = line.substring(tab + 1)
        root._buffer.push({
            id: id,
            text: preview,
            binary: preview.indexOf("[[ binary data") === 0,
        })
    }

    // Put an entry back on the clipboard.
    function copy(id) {
        const value = Number(id)
        if (!isFinite(value))
            return

        // Needs a pipe, so it goes through sh — safe because the only thing
        // interpolated is a number.
        copier.command = ["sh", "-c",
            root.listTool + " decode " + Math.round(value) + " | " + root.copyTool]
        copier.running = true
    }

    function wipe() {
        if (!wiper.running)
            wiper.running = true
    }

    property var _buffer: []

    Process {
        id: lister

        command: [root.listTool, "list"]
        stdout: SplitParser { onRead: line => root.collect(line) }
        onStarted: root._buffer = []

        onExited: (code, status) => {
            if (code === 0) {
                // cliphist lists newest first, but sort by id rather than rely
                // on that: the cap below has to keep the *newest* entries.
                const sorted = root._buffer.slice()
                sorted.sort((a, b) => b.id - a.id)
                root.entries = sorted.slice(0, root.limit)
                root.available = true
            } else {
                // cliphist missing, or something else went wrong.
                root.available = false
            }
        }
    }

    Process {
        id: copier

        onExited: root.refresh()
    }

    Process {
        id: wiper

        command: [root.listTool, "wipe"]
        onExited: root.refresh()
    }

    // Only needs probing while we don't have it, so installing cliphist later is
    // noticed without a steady stream of failed execs in the log. Once it works,
    // the popup drives refreshes itself.
    Timer {
        running: !root.available
        interval: 60000
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
