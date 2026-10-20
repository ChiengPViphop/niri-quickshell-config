pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "."

// Talks to niri over `niri msg --json event-stream`, which pushes the complete
// state up front and then only the changes, so the bar never has to poll.
Singleton {
    id: niri

    // ─── State ───────────────────────────────────────────────────────────────
    property var workspaces: []
    property var windows: []
    property var layouts: ({ names: [], current_idx: 0 })
    property bool overviewOpen: false
    property bool connected: false

    // Bumped when the desktop-entry list finishes loading. Icon lookups made
    // before that point have to be retried, so the workspace bindings read this
    // property and re-evaluate when it changes.
    property int entriesRevision: 0

    // ─── Derived ─────────────────────────────────────────────────────────────
    readonly property string layoutName: {
        const names = layouts.names || []
        if (names.length === 0)
            return ""
        let index = layouts.current_idx || 0
        if (index < 0 || index >= names.length)
            index = 0
        return names[index]
    }

    function workspacesFor(output) {
        const all = workspaces || []
        if (!output)
            return all
        const mine = all.filter(w => w.output === output)
        // Fall back to everything if the output names don't line up, so the
        // workspaces never silently disappear.
        return mine.length > 0 ? mine : all
    }

    function focusedWindowTitle(output) {
        const focused = (windows || []).filter(w => w.is_focused)
        if (focused.length === 0)
            return ""
        const activeIds = workspacesFor(output)
            .filter(w => w.is_active)
            .map(w => w.id)
        const onActive = focused.filter(w => activeIds.indexOf(w.workspace_id) !== -1)
        const window = onActive.length > 0 ? onActive[0] : focused[0]
        return window.title || window.app_id || ""
    }

    // Every window on a workspace, in niri's own order.
    function windowsForWorkspace(workspace) {
        if (!workspace)
            return []
        return (windows || []).filter(w => w.workspace_id === workspace.id)
    }

    // Resolve a niri `app_id` to a desktop entry. `heuristicLookup` matches the
    // id, StartupWMClass and name, which covers the usual mismatches between
    // Wayland app ids and .desktop file names.
    function desktopEntryFor(appId) {
        if (!appId)
            return null
        const direct = DesktopEntries.byId(appId)
        if (direct)
            return direct
        const heuristic = DesktopEntries.heuristicLookup(appId)
        if (heuristic)
            return heuristic
        const lower = appId.toLowerCase()
        return DesktopEntries.byId(lower) || DesktopEntries.heuristicLookup(lower)
    }

    // Image source for one app's icon, or "" when it cannot be resolved (no
    // desktop entry and no theme icon under that name).
    function iconForAppId(appId) {
        if (!appId)
            return ""
        const entry = desktopEntryFor(appId)
        if (entry && entry.icon) {
            const source = Quickshell.iconPath(entry.icon, true)
            if (source !== "")
                return source
        }
        // Unknown desktop entry: the app id itself is sometimes a theme icon.
        return Quickshell.iconPath(appId, true)
    }

    // Icon sources for every window on a workspace, skipping the ones that do
    // not resolve. Reading `entriesRevision` makes the caller's binding re-run
    // once the desktop entries finish loading; a lookup that happened before
    // that would otherwise stay stuck with no icons.
    function iconsForWorkspace(workspace) {
        void niri.entriesRevision
        return windowsForWorkspace(workspace)
            .map(w => iconForAppId(w.app_id))
            .filter(source => source !== "")
    }

    Connections {
        target: DesktopEntries

        function onApplicationsChanged() {
            niri.entriesRevision++
        }
    }

    // ─── Actions ─────────────────────────────────────────────────────────────
    function runAction(args) {
        action.command = ["niri", "msg", "action"].concat(args)
        action.running = true
    }

    function focusWorkspace(index) {
        runAction(["focus-workspace", String(index)])
    }

    function focusWorkspaceUp() {
        runAction(["focus-workspace-up"])
    }

    function focusWorkspaceDown() {
        runAction(["focus-workspace-down"])
    }

    function switchLayout(direction) {
        runAction(["switch-layout", direction])
    }

    function nextLayout() {
        switchLayout("next")
    }

    function previousLayout() {
        switchLayout("prev")
    }

    Process {
        id: action
        command: []
        running: false
    }

    // ─── Event stream ────────────────────────────────────────────────────────
    Process {
        id: events
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        onExited: niri.connected = false
        stdout: SplitParser {
            onRead: line => niri.handleEvent(line)
        }
    }

    // niri may not be running (or may be restarted under us); try again quietly.
    Timer {
        running: !niri.connected
        interval: Config.niriRetryDelay
        repeat: true
        onTriggered: {
            if (!events.running)
                events.running = true
        }
    }

    function handleEvent(line) {
        let event
        try {
            event = JSON.parse(line)
        } catch (error) {
            return
        }
        niri.connected = true

        if (event.WorkspacesChanged !== undefined) {
            niri.workspaces = event.WorkspacesChanged.workspaces
        } else if (event.WindowsChanged !== undefined) {
            niri.windows = event.WindowsChanged.windows
        } else if (event.WindowOpenedOrChanged !== undefined) {
            niri.upsertWindow(event.WindowOpenedOrChanged.window)
        } else if (event.WindowClosed !== undefined) {
            const closed = event.WindowClosed.id
            niri.windows = (niri.windows || []).filter(w => w.id !== closed)
        } else if (event.WindowFocusChanged !== undefined) {
            const focused = event.WindowFocusChanged.id
            niri.windows = (niri.windows || []).map(
                w => Object.assign({}, w, { is_focused: w.id === focused }))
        } else if (event.WorkspaceActivated !== undefined) {
            niri.applyWorkspaceActivation(event.WorkspaceActivated)
        } else if (event.WorkspaceActiveWindowChanged !== undefined) {
            const change = event.WorkspaceActiveWindowChanged
            niri.workspaces = (niri.workspaces || []).map(w => w.id === change.workspace_id
                ? Object.assign({}, w, { active_window_id: change.active_window_id })
                : w)
        } else if (event.WorkspaceUrgencyChanged !== undefined) {
            const change = event.WorkspaceUrgencyChanged
            niri.workspaces = (niri.workspaces || []).map(w => w.id === change.id
                ? Object.assign({}, w, { is_urgent: change.urgent })
                : w)
        } else if (event.KeyboardLayoutsChanged !== undefined) {
            niri.layouts = event.KeyboardLayoutsChanged.keyboard_layouts
        } else if (event.KeyboardLayoutSwitched !== undefined) {
            niri.layouts = {
                names: niri.layouts.names,
                current_idx: event.KeyboardLayoutSwitched.idx,
            }
        } else if (event.OverviewOpenedOrClosed !== undefined) {
            niri.overviewOpen = event.OverviewOpenedOrClosed.is_open
        }
    }

    function upsertWindow(window) {
        if (!window)
            return
        const rest = (niri.windows || []).filter(w => w.id !== window.id)
        niri.windows = rest.concat([window])
    }

    function applyWorkspaceActivation(activation) {
        const target = (niri.workspaces || []).find(w => w.id === activation.id)
        const output = target ? target.output : null
        niri.workspaces = (niri.workspaces || []).map(w => {
            if (w.output !== output)
                return w
            const copy = Object.assign({}, w)
            copy.is_active = (w.id === activation.id)
            if (activation.focused)
                copy.is_focused = (w.id === activation.id)
            return copy
        })
    }
}
