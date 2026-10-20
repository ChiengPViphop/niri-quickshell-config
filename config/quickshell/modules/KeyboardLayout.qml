import QtQuick
import "../theme"
import "../components"
import "../services"
import "../components/Util.js" as Util

// Active keyboard layout. Click or scroll to cycle through the configured
// layouts (niri's `switch-layout` action).
Btn {
    id: root

    readonly property string shortName: Util.shortLayoutName(Niri.layoutName)

    visible: shortName !== ""
    label: shortName
    fg: Theme.subtext
    labelSize: Theme.fontSizeSmall
    horizontalPadding: 6
    tooltip: Niri.layoutName
    onClicked: Niri.nextLayout()
    onScrolled: delta => {
        if (delta < 0)
            Niri.nextLayout()
        else if (delta > 0)
            Niri.previousLayout()
    }
}
