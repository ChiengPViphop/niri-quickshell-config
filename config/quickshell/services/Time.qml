pragma Singleton

import QtQuick
import Quickshell
import "."

// A single system clock shared by every screen's bar.
//
// It ticks in seconds only when the clock is actually showing them, so the bar
// isn't redrawn every second for nothing.
Singleton {
    id: root

    SystemClock {
        id: clock
        enabled: true
        precision: Settings.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    readonly property date now: clock.date

    readonly property string timeFormat: {
        // "hh" is 12-hour with a leading zero, "AP" the AM/PM marker.
        let format = Settings.clock24Hour ? "HH:mm" : "hh:mm AP"
        if (Settings.clockSeconds)
            format += ":ss"
        return format
    }

    readonly property string timeText: Qt.formatDateTime(clock.date, timeFormat)
    readonly property string dayText: Qt.formatDateTime(clock.date, "ddd")

    // What the bar itself shows: optionally the weekday, then the time.
    readonly property string shortTime: (Settings.clockShowDay ? dayText + " " : "")
        + timeText

    readonly property string shortDate: Qt.formatDateTime(clock.date, "ddd d MMM")
    readonly property string longDate: Qt.formatDateTime(clock.date, "dddd d MMMM yyyy")

    // Short weekday names in the right order for the calendar header. Built from
    // real dates so they follow the locale; 2024-01-01 was a Monday.
    function weekdayLabels() {
        const out = []
        for (let i = 0; i < 7; ++i) {
            const offset = Settings.calendarMondayFirst ? i : (i + 6) % 7
            out.push(Qt.formatDateTime(new Date(2024, 0, 1 + offset), "ddd"))
        }
        return out
    }
}
