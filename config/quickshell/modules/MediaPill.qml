import QtQuick
import Quickshell.Services.Mpris
import "../theme"
import "../components"
import "../services"
import "../components/Util.js" as Util

// Now-playing widget for the first MPRIS player. Hidden completely when
// nothing is playing so the middle of the bar stays clean.
Item {
    id: root

    readonly property var players: Mpris.players ? Util.toArray(Mpris.players.values) : []
    readonly property var player: players.length > 0 ? players[0] : null
    readonly property string title: player ? (player.trackTitle || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string label: {
        if (!title)
            return artist
        return artist ? title + "  ·  " + artist : title
    }

    visible: player !== null
    implicitWidth: mediaRow.implicitWidth
    implicitHeight: Theme.itemHeight

    Row {
        id: mediaRow
        anchors.centerIn: parent
        spacing: 1

        Btn {
            icon: Icons.previous
            iconSize: Theme.fontSize
            horizontalPadding: 5
            interactive: root.player !== null && root.player.canGoPrevious
            tooltip: "Previous track"
            onClicked: if (root.player) root.player.previous()
        }

        Btn {
            icon: root.player !== null && root.player.isPlaying ? Icons.pause : Icons.play
            iconSize: Theme.fontSize
            horizontalPadding: 5
            fg: Theme.accent
            interactive: root.player !== null && root.player.canTogglePlaying
            tooltip: root.player !== null && root.player.isPlaying ? "Pause" : "Play"
            onClicked: if (root.player) root.player.togglePlaying()
        }

        Btn {
            icon: Icons.next
            iconSize: Theme.fontSize
            horizontalPadding: 5
            interactive: root.player !== null && root.player.canGoNext
            tooltip: "Next track"
            onClicked: if (root.player) root.player.next()
        }

        Text {
            width: Math.min(implicitWidth, 190)
            height: Theme.itemHeight
            verticalAlignment: Text.AlignVCenter
            leftPadding: 4
            rightPadding: 2
            text: root.label
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
        }
    }
}
