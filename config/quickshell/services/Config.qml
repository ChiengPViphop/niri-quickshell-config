pragma Singleton

import QtQuick
import Quickshell

// Things you are most likely to want to change.
Singleton {
    // Terminal used for desktop entries that ask to be run in one
    // (the `Terminal=true` field in their .desktop file).
    readonly property string terminal: "wezterm"
    // Arguments inserted before the command to run. WezTerm needs
    // `start -- command`; alacritty/kitty would use ["-e"] instead.
    readonly property var terminalArgs: ["start", "--"]

    // Lock action. No screen locker is installed on this system yet, so this
    // only asks logind to lock the session. Install one and point this at it:
    //   readonly property var lockCommand: ["swaylock", "-f"]
    //   readonly property var lockCommand: ["hyprlock"]
    //   readonly property var lockCommand: ["gtklock"]
    readonly property var lockCommand: ["loginctl", "lock-session"]

    // How long the bar waits before retrying the niri event stream (ms).
    readonly property int niriRetryDelay: 5000

    // How long a notification toast stays up when the sender does not ask for a
    // specific timeout (ms). 0 keeps it until dismissed. Critical notifications
    // never expire on their own, whatever this is.
    readonly property int notificationTimeout: 6000
}
