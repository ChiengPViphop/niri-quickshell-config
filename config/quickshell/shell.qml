import QtQuick
import Quickshell
import Quickshell.Io
import "components"
import "modules"
import "services"

// Entry point. One bar per connected screen.
ShellRoot {
    // Behind everything, one per output. Hidden until a wallpaper is picked.
    Variants {
        model: Quickshell.screens

        WallpaperWindow {}
    }

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    // Notifications belong to the whole session, not to one bar, so the toast
    // stack lives here rather than on the bar.
    NotificationStack {}

    // Owns the session's polkit agent. One instance only: the agent registers
    // with polkitd for the whole shell, and works on whichever output is
    // focused when a request arrives.
    PolkitDialog {}

    // Lives here rather than on the bar so there is only ever one handler, no
    // matter how many screens are connected.
    IpcHandler {
        target: "island"

        function toggle(): void { Island.toggle() }
        function open(): void { Island.expanded = true }
        function close(): void { Island.collapse() }
        function rearrange(): void { Island.toggleRearrange() }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void { Popups.toggle("settings") }
        function open(): void { Popups.open = "settings" }
        function close(): void { Popups.close() }
    }
}
