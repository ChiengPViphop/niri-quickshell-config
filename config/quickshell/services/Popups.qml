pragma Singleton

import QtQuick
import Quickshell

// Only one popup is open at a time. Each popup watches `open` instead of
// binding `visible` directly, because `visible` is also written from outside
// (a popup hides itself when dismissed) and a write from C++ would destroy a
// QML binding.
Singleton {
    id: popups

    property string open: ""

    function toggle(name) {
        open = (open === name) ? "" : name
    }

    function close() {
        open = ""
    }

    function isOpen(name) {
        return open === name
    }
}
