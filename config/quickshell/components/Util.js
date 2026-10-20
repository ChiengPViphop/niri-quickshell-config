.pragma library

// Small helpers shared by the bar. A QML sequence type (QObjectList) supports
// `.length` and indexing but not the Array methods, so normalise it first.

function toArray(sequence) {
    const out = []
    if (!sequence)
        return out
    for (let i = 0; i < sequence.length; i++)
        out.push(sequence[i])
    return out
}

function clamp(value, min, max) {
    return Math.min(max, Math.max(min, value))
}

function clamp01(value) {
    return clamp(value, 0, 1)
}

function percent(fraction) {
    return Math.round(clamp01(fraction) * 100)
}

// Strip the field codes out of a .desktop Exec line ("%U", "%f", ...) so it
// can be handed to a shell.
function cleanExec(execString) {
    if (!execString)
        return ""
    return execString.replace(/%[a-zA-Z]/g, "").replace(/\s+/g, " ").trim()
}

// "English (US)" -> "US", "German" -> "GER"
function shortLayoutName(name) {
    if (!name)
        return ""
    const match = /\(([^)]+)\)/.exec(name)
    if (match)
        return match[1].toUpperCase()
    return name.substring(0, 3).toUpperCase()
}
