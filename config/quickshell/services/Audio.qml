pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "."
import "../components/Util.js" as Util

// Thin wrapper around the default PipeWire sink.
//
// PipeWire objects are *unbound* by default: without a PwObjectTracker the
// node reports no channels and a volume of 0. The tracker below is what makes
// the volume readable and writable.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool available: Pipewire.ready && sink !== null
    readonly property bool bound: sink !== null && sink.ready
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : true
    readonly property real volume: {
        if (!sink || !sink.audio)
            return 0
        if (!sink.audio.volumes || sink.audio.volumes.length === 0)
            return 0
        return sink.audio.volume
    }
    readonly property int percent: Util.percent(volume)
    readonly property string description: sink ? (sink.description || sink.name) : ""

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    function setVolume(value) {
        if (!sink || !sink.audio)
            return
        sink.audio.volume = Util.clamp(value, 0, 1.5)
    }

    function changeVolume(delta) {
        setVolume(volume + delta)
    }

    function toggleMute() {
        if (sink && sink.audio)
            sink.audio.muted = !sink.audio.muted
    }
}
