import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../theme"
import "../components"
import "../services"
import "../components/Util.js" as Util

// System tray. Left click activates an item, right click opens its menu when
// it has one. The menu popup is shared and anchored to the tray as a whole.
Item {
    id: root

    readonly property var trayItems: SystemTray.items
        ? Util.toArray(SystemTray.items.values) : []

    property var activeItem: null
    property string hoverText: ""

    visible: trayItems.length > 0
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.itemHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.trayItems

            delegate: Item {
                id: cell

                required property var modelData

                width: 22
                height: Theme.itemHeight

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.itemRadius
                    color: hover.hovered ? Theme.hoverSoft : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                // `icon` is already an image:// URL ready to use as a source.
                // Passing it through Quickshell.iconPath() would look it up as a
                // *theme icon name*, which always fails and left every item on
                // its fallback glyph.
                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    sourceSize: Qt.size(32, 32)
                    source: cell.modelData.icon
                    visible: cell.modelData.icon !== ""
                    smooth: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: cell.modelData.icon === ""
                    text: Icons.arch
                    color: Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLarge
                }

                HoverHandler {
                    id: hover

                    onHoveredChanged: {
                        if (hovered)
                            root.hoverText = cell.modelData.tooltipTitle
                                || cell.modelData.title || ""
                        else if (root.hoverText !== "")
                            root.hoverText = ""
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => root.activate(cell.modelData, mouse.button)
                    onWheel: wheel => cell.modelData.scroll(wheel.angleDelta.y / 120)
                }
            }
        }
    }

    // Item title on hover.
    PopupWindow {
        id: tooltip

        visible: root.hoverText !== ""
        color: "transparent"
        grabFocus: false
        implicitWidth: tipLabel.implicitWidth + 16
        implicitHeight: tipLabel.implicitHeight + 8

        anchor {
            item: root
            edges: Edges.Bottom
            gravity: Edges.Bottom
        }

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: Theme.bg
            border.width: 1
            border.color: Theme.outline

            Text {
                id: tipLabel
                anchors.centerIn: parent
                text: root.hoverText
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }

    Popup {
        id: menuPopup

        name: "tray"
        heading: root.activeItem
            ? (root.activeItem.tooltipTitle || root.activeItem.title || "Menu")
            : "Menu"
        anchorItem: root
        anchorEdges: Edges.Bottom | Edges.Right
        anchorGravity: Edges.Bottom | Edges.Left

        QsMenuOpener {
            id: opener
            menu: root.activeItem ? root.activeItem.menu : null
        }

        Repeater {
            model: opener.children ? Util.toArray(opener.children.values) : []

            delegate: RowButton {
                required property var modelData

                Layout.fillWidth: true
                visible: !modelData.isSeparator
                interactive: modelData.enabled
                label: modelData.text
                glyph: modelData.checkState === Qt.Checked ? Icons.check : ""
                glyphColor: Theme.accent
                highlighted: modelData.checkState === Qt.Checked
                onClicked: {
                    modelData.triggered()
                    Popups.close()
                }
            }
        }
    }

    function activate(item, button) {
        if (!item)
            return

        const hasMenu = item.hasMenu && item.menu

        if ((button === Qt.RightButton && hasMenu) || item.onlyMenu === true) {
            if (!hasMenu) {
                item.secondaryActivate()
                return
            }
            if (root.activeItem === item && Popups.isOpen("tray")) {
                Popups.close()
            } else {
                root.activeItem = item
                Popups.open = "tray"
            }
            return
        }

        if (button === Qt.RightButton) {
            item.secondaryActivate()
            return
        }

        item.activate()
    }
}
