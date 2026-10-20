pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification daemon, and the unread counter the bar's dot reads.
//
// Quickshell can own org.freedesktop.Notifications itself, so the bar needs no
// separate daemon (dunst, mako, ...): `NotificationServer` implements the D-Bus
// interface and hands each notification over through `onNotification`.
//
// `unread` counts notifications the user has not acknowledged. One that simply
// times out stays unread — that is what the dot is for — while dismissing it,
// clicking the dot, or expanding the island clears it.
//
// Actions are deliberately not advertised: Quickshell 0.3.2 dismisses a
// notification carrying them a moment after it arrives, so a sender that offers
// actions would never get a toast at all. Everything else shows.
Singleton {
    id: root

    // The live notifications, served straight from the server's own model so
    // nothing has to be mirrored by hand.
    readonly property var list: server.trackedNotifications
    readonly property var values: root.list ? root.list.values : []
    readonly property int count: root.values.length

    // Unread notifications, and how many of those are critical. The urgency is
    // counted separately so the dot can turn red.
    property int unread: 0
    property int urgentUnread: 0

    readonly property bool hasUnread: root.unread > 0
    readonly property bool urgent: root.urgentUnread > 0

    NotificationServer {
        id: server

        // We render a plain body and one image (the icon); ask the senders for
        // exactly that so markup never shows up raw.
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: false
        actionIconsSupported: false
        imageSupported: true
        inlineReplySupported: false

        onNotification: notification => root.track(notification)
    }

    function track(notification) {
        // Without this the server discards the notification as soon as the
        // signal handler returns, which is why nothing ever appeared on screen.
        // `tracked` keeps it in `trackedNotifications` until we dismiss or
        // expire it. Notifications re-emitted after a reload arrive here too,
        // which is what restores the unread count.
        notification.tracked = true
        root.unread++
        const critical = notification.urgency === NotificationUrgency.Critical
        if (critical)
            root.urgentUnread++
        // The urgency is captured now because the notification object is gone
        // by the time it closes.
        notification.closed.connect(reason => root.onClosed(critical, reason))
    }

    // A toast that timed out is still unread; only a dismissal acknowledges it.
    function onClosed(critical, reason) {
        if (reason !== NotificationCloseReason.Dismissed)
            return
        root.unread = Math.max(0, root.unread - 1)
        if (critical)
            root.urgentUnread = Math.max(0, root.urgentUnread - 1)
    }

    function markRead() {
        root.unread = 0
        root.urgentUnread = 0
    }

    function dismiss(notification) {
        if (notification)
            notification.dismiss()
    }

    function dismissAll() {
        for (const notification of root.values.slice())
            notification.dismiss()
    }

    // Image source for a notification's icon: the resolved image first, then an
    // app icon by path or theme name, then the desktop entry's icon.
    function iconFor(notification) {
        if (!notification)
            return ""
        if (notification.image)
            return notification.image
        const icon = notification.appIcon
        if (icon) {
            if (icon.indexOf("/") !== -1 || icon.indexOf("image://") === 0)
                return icon
            const resolved = Quickshell.iconPath(icon, true)
            if (resolved !== "")
                return resolved
        }
        if (notification.desktopEntry) {
            const entry = DesktopEntries.byId(notification.desktopEntry)
            if (entry && entry.icon) {
                const resolved = Quickshell.iconPath(entry.icon, true)
                if (resolved !== "")
                    return resolved
            }
        }
        return ""
    }

    // Auto-expire delay in ms; 0 means "stay until dismissed". Critical
    // notifications never time out on their own, and senders that pass no
    // timeout get the default from Config.
    function timeoutFor(notification) {
        if (!notification)
            return 0
        if (notification.urgency === NotificationUrgency.Critical)
            return 0
        if (notification.expireTimeout > 0)
            return notification.expireTimeout
        return Config.notificationTimeout
    }
}
