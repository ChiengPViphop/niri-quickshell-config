import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../components"
import "../services"

// The clock. Left click folds the island away (or brings it back), right click
// opens a month calendar.
//
// This doubles as the island's collapse control: the bar's own padding and the
// empty strip deliberately do nothing, so the clock is the one place that puts
// the island away.
Btn {
    id: root

    // The month being looked at in the calendar.
    property int shownYear: Time.now.getFullYear()
    property int shownMonth: Time.now.getMonth()

    label: Time.shortTime
    fg: Theme.text
    labelSize: Theme.fontSize
    horizontalPadding: 6
    highlighted: Popups.isOpen("calendar")
    tooltip: Time.longDate
    onClicked: Island.toggle()
    onSecondaryClicked: Popups.toggle("calendar")

    readonly property string monthTitle: Qt.formatDateTime(
        new Date(root.shownYear, root.shownMonth, 1), "MMMM yyyy")

    // 42 cells: the whole month plus however much of the neighbouring months is
    // needed to fill the leading and trailing weeks.
    readonly property var cells: {
        const first = new Date(root.shownYear, root.shownMonth, 1)
        const lead = Settings.calendarMondayFirst ? 1 : 0
        const offset = (first.getDay() - lead + 7) % 7
        const days = new Date(root.shownYear, root.shownMonth + 1, 0).getDate()
        const before = new Date(root.shownYear, root.shownMonth, 0).getDate()
        const today = Time.now

        const out = []
        for (let i = 0; i < 42; ++i) {
            const day = i - offset + 1
            const outside = day < 1 || day > days
            const number = day < 1 ? before + day : day > days ? day - days : day
            out.push({
                number: number,
                outside: outside,
                // Only the current month can hold "today".
                today: !outside
                    && number === today.getDate()
                    && root.shownMonth === today.getMonth()
                    && root.shownYear === today.getFullYear(),
            })
        }
        return out
    }

    Popup {
        id: calendarPopup

        name: "calendar"
        heading: Time.longDate

        // A month grid belongs at the top of the screen, centred horizontally,
        // rather than hanging off the clock like the little popups or floating
        // in the middle of a window. `anchorItem` is still set so it lands on
        // the right monitor, and the visibility check still applies so only the
        // clock instance actually on screen can open it.
        centered: true
        centeredVertically: false
        anchorItem: root

        // Everything in this card is centred, heading included.
        surfaceItem.centerTitle: true

        // Step a month, or jump back to today when the popup is reopened.
        function step(delta) {
            const date = new Date(root.shownYear, root.shownMonth + delta, 1)
            root.shownYear = date.getFullYear()
            root.shownMonth = date.getMonth()
        }

        onVisibleChanged: if (visible) {
            root.shownYear = Time.now.getFullYear()
            root.shownMonth = Time.now.getMonth()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Btn {
                icon: Icons.chevronLeft
                iconSize: Theme.fontSize
                horizontalPadding: 6
                tooltip: "Previous month"
                onClicked: calendarPopup.step(-1)
            }

            Text {
                Layout.fillWidth: true
                text: root.monthTitle
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }

            Btn {
                icon: Icons.chevronRight
                iconSize: Theme.fontSize
                horizontalPadding: 6
                tooltip: "Next month"
                onClicked: calendarPopup.step(1)
            }
        }

        Grid {
            Layout.alignment: Qt.AlignHCenter
            columns: 7
            spacing: 2

            Repeater {
                model: Time.weekdayLabels()

                delegate: Text {
                    required property string modelData

                    width: 30
                    height: 20
                    text: modelData
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Repeater {
                model: root.cells

                delegate: Rectangle {
                    required property var modelData

                    width: 30
                    height: 26
                    radius: Theme.itemRadius
                    color: modelData.today ? Theme.accentSoft : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.number
                        color: modelData.today ? Theme.accent
                            : modelData.outside ? Theme.muted
                            : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: modelData.today ? Font.DemiBold : Font.Normal
                    }
                }
            }
        }
    }
}
