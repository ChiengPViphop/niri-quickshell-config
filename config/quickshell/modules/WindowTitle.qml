import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"

// Title of the focused window on this output, elided to keep the bar tidy.
Text {
    id: root

    property string output: ""
    property real maximumWidth: 280

    readonly property string liveTitle: Niri.focusedWindowTitle(output)

    // While a popup is open it holds exclusive keyboard focus, so niri reports
    // no focused window and `liveTitle` momentarily empties. Keep showing the
    // last known title for as long as that is happening, so the bar doesn't
    // flicker as popups open and close.
    property string lastTitle: ""
    readonly property string windowTitle: liveTitle !== ""
        ? liveTitle : (Popups.open !== "" ? lastTitle : "")

    onLiveTitleChanged: if (liveTitle !== "") root.lastTitle = liveTitle

    Layout.alignment: Qt.AlignVCenter
    Layout.maximumWidth: root.maximumWidth
    Layout.leftMargin: 2

    text: windowTitle
    visible: windowTitle !== ""
    color: Theme.subtext
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    elide: Text.ElideRight
}
