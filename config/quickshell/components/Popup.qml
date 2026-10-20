import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// A popup card, modal while it is open.
//
// This is a full-screen overlay layer-surface holding a click-catching
// background plus the card, rather than Quickshell's PopupWindow (an
// xdg_popup). Two reasons, both of which bite on niri:
//
//   * Keyboard. An xdg_popup whose parent layer-surface has
//     keyboard_interactivity = none is never given keyboard focus, so a
//     PopupWindow can never be typed into. A layer surface can ask for
//     keyboard focus in its own right, and niri grants Exclusive focus to the
//     top-most overlay surface, so the launcher's search field works.
//   * Dismissal. A click anywhere that is not the card lands on our own
//     background, so no compositor-side popup grab is involved.
//
// `visible` is set imperatively rather than bound, because the value is also
// written from outside and a C++ write would destroy a QML binding.
PanelWindow {
    id: root

    // Key used with Popups.open / Popups.toggle().
    property string name: ""

    // The item the popup hangs off, usually the button that opens it.
    property Item anchorItem: null

    // Which edges of the anchor item the card attaches to. The card always
    // sits below it; Left or Right decides which horizontal edge lines up.
    property var anchorEdges: Edges.Bottom
    property var anchorGravity: Edges.Bottom | Edges.Right

    // Children land inside the card's column, below the heading.
    default property alias content: surface.content
    property alias surfaceItem: surface
    property alias heading: surface.title

    readonly property int cardGap: 6
    readonly property int screenMargin: 8

    // Per-popup nudge, in pixels: positive X moves right, positive Y moves
    // down. Set these at the call site to line a card up with something other
    // than the anchor item's edge, e.g. `offsetX: -40`.
    property real offsetX: 0
    property real offsetY: 0

    // Centre the card on the screen instead of hanging it off `anchorItem`.
    property bool centered: false

    // With `centered`, also centre vertically. Set it false to pin the card to
    // the top of the screen instead, still horizontally centred — the calendar
    // uses that so it sits just under the bar rather than in the middle of
    // whatever window happens to be open.
    property bool centeredVertically: true

    // Distance from the top of the screen when `centered` is on and
    // `centeredVertically` is off. Defaults to clearing the bar.
    property real topMargin: Theme.barHeight + 8

    // Dim and blur whatever is behind the panel. The launcher uses both; small
    // menus leave them off so they stay lightweight.
    property real dim: 0
    property bool blur: false

    // Layer-shell namespace. The launcher gets its own so a compositor rule can
    // target it alone (see the README's blur notes); everything else shares the
    // default and stays unblurred.
    property string layerNamespace: "quickshell-popup"

    // Position of the anchor item inside this window.
    //
    // Walked by hand rather than via Item.mapToItem() / window.itemPosition(),
    // because those are plain calls: a binding that only calls them has no
    // property dependencies and would freeze at whatever position the bar had
    // on the first frame. Summing x/y up the chain gives the binding something
    // to depend on, so it re-evaluates whenever the bar re-lays itself out
    // (a tray icon appearing, the window title growing, and so on).
    function scenePosition(item) {
        let x = 0
        let y = 0
        let node = item
        while (node) {
            x += node.x
            y += node.y
            node = node.parent
        }
        return Qt.point(x, y)
    }

    readonly property point anchorPos: root.anchorItem
        ? root.scenePosition(root.anchorItem) : Qt.point(0, 0)

    readonly property real anchorWidth: root.anchorItem ? root.anchorItem.width : 0
    readonly property real anchorHeight: root.anchorItem ? root.anchorItem.height : 0

    readonly property int attachEdge: {
        if (root.anchorEdges & Edges.Right)
            return Edges.Right
        if (root.anchorEdges & Edges.Left)
            return Edges.Left
        if (root.anchorGravity & Edges.Right)
            return Edges.Right
        if (root.anchorGravity & Edges.Left)
            return Edges.Left
        return 0
    }

    readonly property real cardX: {
        if (root.centered)
            return Math.round((root.availableWidth - surface.width) / 2)

        const left = anchorPos.x
        const right = left + anchorWidth
        let x = left
        if (root.attachEdge === Edges.Right)
            x = right - surface.width
        else if (root.attachEdge === 0)
            x = (left + right - surface.width) / 2
        // Keep the default cards off the screen edges...
        const maximum = Math.max(screenMargin,
            root.availableWidth - surface.width - screenMargin)
        x = Math.max(screenMargin, Math.min(maximum, x))
        // ...then apply the per-popup nudge, which is allowed to reach the edge.
        const hardMaximum = Math.max(0, root.availableWidth - surface.width)
        return Math.round(Math.max(0, Math.min(hardMaximum, x + root.offsetX)))
    }

    readonly property real cardY: root.centered
        ? (root.centeredVertically
            ? Math.round((root.availableHeight - surface.height) / 2)
            : Math.round(root.topMargin + root.offsetY))
        : Math.round(anchorPos.y + anchorHeight + cardGap + root.offsetY)

    // The window's own width/height are still 0 on the frame the popup is
    // shown, so clamp against the monitor instead.
    readonly property real availableWidth: root.screen ? root.screen.width : root.width
    readonly property real availableHeight: root.screen ? root.screen.height : root.height

    // Where this bar's window sits on its screen. Combined with anchorPos
    // below to give the anchor's position in screen coordinates.
    readonly property point sceneOrigin: {
        if (!root.anchorItem)
            return Qt.point(0, 0)
        const global = root.anchorItem.mapToGlobal(0, 0)
        const scene = root.anchorPos
        return Qt.point(global.x - scene.x, global.y - scene.y)
    }

    readonly property point anchorGlobal: Qt.point(root.sceneOrigin.x + root.anchorPos.x,
        root.sceneOrigin.y + root.anchorPos.y)

    // Show on the same monitor as the bar this popup belongs to.
    screen: {
        const point = root.anchorGlobal
        const screens = Quickshell.screens
        for (let i = 0; i < screens.length; ++i) {
            const s = screens[i]
            if (point.x >= s.x && point.x < s.x + s.width
                && point.y >= s.y && point.y < s.y + s.height)
                return s
        }
        return null
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // -1 tells the compositor to stretch this surface all the way to the edges
    // it is anchored to. With the default of 0 the compositor instead moves it
    // out of the way of our own bar's exclusive zone, which would shift the
    // whole overlay down by the bar height and leave every card floating far
    // below the item it belongs to. It also must not reserve space itself.
    exclusiveZone: -1
    color: root.dim > 0 ? Qt.rgba(0, 0, 0, root.dim) : "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: root.layerNamespace

    // Blur everything behind the panel. The region is a plain Region (a QObject,
    // not an item), so it has no visual side effects of its own.
    BackgroundEffect.blurRegion: root.blur ? blurRegion : null

    Region {
        id: blurRegion
        item: background
    }

    // Anything that is not the card dismisses the popup. This also holds the
    // keyboard focus while the popup is open, which is what makes Escape work.
    MouseArea {
        id: background

        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        focus: true
        onClicked: Popups.close()
        onWheel: wheel => wheel.accepted = true
        Keys.onEscapePressed: Popups.close()
    }

    PopupSurface {
        id: surface

        x: root.cardX
        y: root.cardY
    }

    // Only the visible instance of a duplicated module may open its popup.
    //
    // A module can exist twice — `clock` is in both the collapsed pill's group and
    // the expanded centre group — and both instances answer to the same popup
    // name, so without this a click opened the popup twice.
    //
    // Centred popups can be opened while the bar is collapsed (the launcher, from
    // a keybind), so those set this false. A centred popup that still has a real
    // anchor, like the calendar, keeps the check.
    property bool anchorMustBeVisible: true

    readonly property bool anchorUsable: !root.anchorMustBeVisible
        || root.anchorItem === null || root.anchorItem.visible

    function sync() {
        root.visible = root.name !== "" && Popups.open === root.name && root.anchorUsable
    }

    onAnchorUsableChanged: root.sync()

    onVisibleChanged: {
        if (!root.visible && Popups.open === root.name)
            Popups.open = ""
    }

    Connections {
        target: Popups

        function onOpenChanged() {
            root.sync()
        }
    }

    Component.onCompleted: root.sync()
}
