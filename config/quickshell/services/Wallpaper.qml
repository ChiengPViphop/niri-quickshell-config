pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper discovery and helpers.
//
// The bar draws the wallpaper itself (see components/WallpaperWindow.qml), so
// this service only needs to find image files and hand the settings panel a
// list to show. The chosen path lives in Settings, next to the other values.
Singleton {
    id: root

    // Folders searched for images. Add your own here; the scan is recursive to
    // three levels, so a folder-per-collection layout works.
    readonly property var folders: {
        const home = Quickshell.env("HOME") || ""
        return [
            home + "/Pictures/Wallpapers",
            "/usr/share/wallpapers",
            "/usr/share/backgrounds",
        ]
    }

    property var entries: []
    property bool scanning: false

    // The grid's model: a "None" tile followed by every discovered image.
    readonly property var choices: {
        const list = [{ path: "", name: "None" }]
        for (let i = 0; i < root.entries.length; ++i)
            list.push(root.entries[i])
        return list
    }

    // Every path is single-quoted for the shell. The folders are already
    // absolute paths, so no expansion is needed.
    readonly property string scanCommand: {
        const dirs = root.folders.map(folder => "'" + folder.replace(/'/g, "'\\''") + "'")
        return "find " + dirs.join(" ") + " -maxdepth 3 -type f "
            + "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' "
            + "-o -iname '*.webp' -o -iname '*.bmp' \\) -print 2>/dev/null | sort"
    }

    // Source URL with spaces and other awkward characters escaped. Qt accepts a
    // plain absolute path too, but percent-encoding keeps `#` and `?` in file
    // names from being mistaken for URL syntax.
    function sourceFor(path) {
        if (!path)
            return ""
        // Allow ~/... in a hand-edited settings.json as well as absolute paths.
        if (path.startsWith("~/"))
            path = (Quickshell.env("HOME") || "") + path.substring(1)
        return "file://" + path.split("/").map(encodeURIComponent).join("/")
    }

    function nameFor(path) {
        if (!path)
            return "None"
        const base = path.substring(path.lastIndexOf("/") + 1)
        const dot = base.lastIndexOf(".")
        return dot > 0 ? base.substring(0, dot) : base
    }

    function fillModeFor(mode) {
        switch (mode) {
        case "fit":
            return Image.PreserveAspectFit
        case "stretch":
            return Image.Stretch
        case "tile":
            return Image.Tile
        default:
            return Image.PreserveAspectCrop
        }
    }

    function refresh() {
        if (finder.running)
            return
        root.scanning = true
        root._buffer = []
        finder.running = true
    }

    property var _buffer: []

    Process {
        id: finder

        command: ["sh", "-c", root.scanCommand]
        running: false

        stdout: SplitParser {
            onRead: line => {
                const path = line.trim()
                if (path !== "")
                    root._buffer.push(path)
            }
        }

        onStarted: root._buffer = []

        onExited: {
            const seen = {}
            const list = []
            for (let i = 0; i < root._buffer.length; ++i) {
                const path = root._buffer[i]
                if (seen[path])
                    continue
                seen[path] = true
                list.push({ path: path, name: root.nameFor(path) })
            }

            list.sort((a, b) => a.name.localeCompare(b.name))
            root.entries = list
            root.scanning = false
        }
    }

    Component.onCompleted: root.refresh()
}
