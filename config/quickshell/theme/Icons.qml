pragma Singleton

import QtQuick
import Quickshell

// Every glyph in this file is a Nerd Font codepoint that has been checked
// against the installed fonts, so nothing renders as a "tofu" box.
// Browse more at https://www.nerdfonts.com/cheat-sheet
Singleton {
    readonly property string arch: "\uf303"

    readonly property string search: "\uf002"
    readonly property string check: "\uf00c"
    readonly property string close: "\uf00d"

    readonly property string volumeHigh: "\uf028"
    readonly property string volumeLow: "\uf027"
    readonly property string volumeOff: "\uf026"

    readonly property string brightness: "\uf185"

    readonly property string clipboard: "\uf0ea"
    readonly property string trash: "\uf1f8"

    readonly property string wifi: "\uf1eb"
    readonly property string wifiOff: "\uf05e"
    readonly property string globe: "\uf0ac"
    readonly property string link: "\uf0c1"
    readonly property string signal: "\uf2f5"
    readonly property string bluetooth: "\uf293"

    readonly property string batteryFull: "\uf240"
    readonly property string battery75: "\uf241"
    readonly property string battery50: "\uf242"
    readonly property string battery25: "\uf243"
    readonly property string batteryEmpty: "\uf244"
    readonly property string bolt: "\uf0e7"

    readonly property string media: "\uf001"
    readonly property string play: "\uf04b"
    readonly property string pause: "\uf04c"
    readonly property string next: "\uf051"
    readonly property string previous: "\uf048"

    readonly property string power: "\uf011"
    readonly property string lock: "\uf023"
    readonly property string suspend: "\uf186"
    readonly property string reboot: "\uf021"
    readonly property string logout: "\uf08b"

    readonly property string chevronLeft: "\uf053"
    readonly property string chevronRight: "\uf054"
    readonly property string cog: "\uf013"
}
