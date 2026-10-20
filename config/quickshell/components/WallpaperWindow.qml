import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// One wallpaper surface per screen, on the background layer.
//
// Drawing it here rather than with swaybg / hyprpaper means the wallpaper has no
// extra process to start and follows the bar's live reloads. An empty path
// hides the surface, leaving niri's own backdrop colour visible.
PanelWindow {
    id: root

    required property var modelData

    screen: modelData

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // -1 stretches the surface to every anchored edge and reserves no space of
    // its own, matching the popup overlays. The background layer keeps it below
    // normal windows.
    exclusiveZone: -1
    color: Theme.bg
    visible: Settings.wallpaperPath !== ""
    focusable: false

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-wallpaper"

    Image {
        anchors.fill: parent
        source: Wallpaper.sourceFor(Settings.wallpaperPath)
        fillMode: Wallpaper.fillModeFor(Settings.wallpaperMode)
        asynchronous: true
        cache: true
        smooth: true
        mipmap: true
    }
}
