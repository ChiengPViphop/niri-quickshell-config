pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Screen brightness, via brightnessctl.
//
// brightnessctl's udev rule is what allows writing the backlight without root;
// on Arch it comes with the package (`sudo pacman -S brightnessctl`). On a
// machine without the tool, or without a backlight, the pill simply never shows.
//
// There is nothing to subscribe to, so the level is polled: often while we know
// the device is there, rarely when we don't, so a later install gets picked up
// without spamming the log.
Singleton {
    id: root

    readonly property string tool: "brightnessctl"

    property bool available: false
    property int percent: 0

    function set(value) {
        const target = Math.max(1, Math.min(100, Math.round(value)))
        if (target === root.percent)
            return

        // Move the UI first so scrolling feels immediate; the read afterwards
        // puts the real value back if the write was refused.
        root.percent = target
        setter.command = [root.tool, "--class=backlight", "set", target + "%"]
        setter.running = true
    }

    function change(delta) {
        root.set(root.percent + delta)
    }

    function read() {
        if (!reader.running)
            reader.running = true
    }

    // Parses the machine-readable info line, which looks like
    //   intel_backlight,backlight,7500,100%,7500
    // taking whichever field is a percentage rather than trusting a position.
    function parse(text) {
        const fields = String(text).trim().split(",")
        for (let i = 0; i < fields.length; ++i) {
            const field = fields[i].trim()
            if (field.charAt(field.length - 1) !== "%")
                continue
            const value = parseInt(field, 10)
            if (!isNaN(value)) {
                root.percent = value
                root.available = true
                return
            }
        }
        root.available = false
    }

    Process {
        id: reader

        command: [root.tool, "--class=backlight", "--machine-readable", "info"]
        stdout: SplitParser { onRead: line => root.parse(line) }
        onExited: (code, status) => {
            if (code !== 0)
                root.available = false
        }
    }

    Process {
        id: setter

        // Confirm what actually landed on the device.
        onExited: root.read()
    }

    Timer {
        running: root.available
        interval: 3000
        repeat: true
        onTriggered: root.read()
    }

    Timer {
        running: !root.available
        interval: 60000
        repeat: true
        onTriggered: root.read()
    }

    Component.onCompleted: root.read()
}
