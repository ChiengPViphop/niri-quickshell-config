import QtQuick
import Quickshell.Services.UPower
import "../theme"
import "../components"
import "../services"

// Battery percentage and charge state. Only shown on machines that actually
// have a battery. Clicking cycles the power profile.
Btn {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: device !== null && device.isPresent
    readonly property int level: device ? Math.round(device.percentage) : 0
    readonly property bool charging: device !== null
        && (device.state === UPowerDeviceState.Charging
            || device.state === UPowerDeviceState.FullyCharged
            || device.state === UPowerDeviceState.PendingCharge)
    readonly property bool discharging: device !== null
        && device.state === UPowerDeviceState.Discharging

    readonly property string profileLabel: {
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver: return "Power saver"
        case PowerProfile.Performance: return "Performance"
        default: return "Balanced"
        }
    }

    readonly property string remaining: {
        if (!device)
            return ""
        const seconds = charging ? device.timeToFull : device.timeToEmpty
        if (!seconds || seconds <= 0 || seconds > 60 * 60 * 30)
            return ""
        const hours = Math.floor(seconds / 3600)
        const minutes = Math.round((seconds % 3600) / 60)
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m"
    }

    visible: present

    icon: charging ? Icons.bolt
        : level >= 90 ? Icons.batteryFull
        : level >= 65 ? Icons.battery75
        : level >= 40 ? Icons.battery50
        : level >= 15 ? Icons.battery25
        : Icons.batteryEmpty

    label: present ? level + "%" : ""
    labelSize: Theme.fontSizeSmall
    horizontalPadding: 6
    fg: charging ? Theme.green : (level <= 15 ? Theme.red : Theme.subtext)

    tooltip: {
        if (!present)
            return ""
        const parts = [level + "%" + (charging ? " (charging)" : "")]
        if (remaining !== "")
            parts.push(remaining + (charging ? " until full" : " left"))
        if (PowerProfiles.hasPerformanceProfile)
            parts.push(profileLabel)
        return parts.join(" · ")
    }

    onClicked: cycleProfile()

    function cycleProfile() {
        if (!PowerProfiles.hasPerformanceProfile)
            return
        const order = [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
        const index = order.indexOf(PowerProfiles.profile)
        PowerProfiles.profile = order[(index + 1) % order.length]
    }
}
