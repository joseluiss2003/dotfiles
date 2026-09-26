pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "BorderGeometry.js" as Geometry

// Omarchy Color compatibility layer for Sway + Matugen.
//
// Important: this intentionally does NOT import a Generated QML module.
// Quickshell's import path does not automatically expose
// ~/.config/quickshell/generated as a module, even when that directory has a
// qmldir declaring `module Generated`. Instead we watch Matugen's generated
// Theme.qml directly and mirror its color roles into Omarchy's Color API.
//
// This makes Matugen the source of truth for:
//   - bar background/text/active accent
//   - popup/tooltip backgrounds and borders
//   - menu selections
//   - notifications / polkit / lock / image picker
//   - generic foreground/accent/error/muted roles used by applets
QtObject {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateHome: home + "/.local/state"
  readonly property string currentThemePath: stateHome + "/omarchy/current/theme"
  readonly property string matugenThemePath: home + "/.config/quickshell/generated/Theme.qml"

  // Parsed Matugen colors. Values are kept as strings so missing roles can
  // safely fall back without making the singleton itself invalid.
  property var matugenColors: ({
    background: "#000000",
    text: "#ffffff",
    surface: "#111111",
    surfaceAlt: "#1a1a1a",
    textMuted: "#bbbbbb",
    accent: "#ffffff",
    accentText: "#000000",
    accentSoft: "#333333",
    secondary: "#aaaaaa",
    tertiary: "#aaaaaa",
    outline: "#777777",
    error: "#ff5555"
  })

  function colorFromValue(value, fallback) {
    var s = String(value || "").trim()
    if (!/^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$/.test(s)) return fallback
    return Qt.color(s)
  }

  function parseMatugen(raw) {
    var text = String(raw || "")
    var next = {}
    for (var key in root.matugenColors) next[key] = root.matugenColors[key]

    // Matches the exact format produced by the user's matugen template:
    // readonly property color background: "#RRGGBB"
    // Also accepts `property color ...` without readonly for robustness.
    var re = /(?:readonly\s+)?property\s+color\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*["'](#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?)["']/g
    var match
    var matched = 0
    while ((match = re.exec(text)) !== null) {
      next[match[1]] = match[2]
      matched++
    }

    // Only publish a new palette when the generated file contains the core
    // roles. During Matugen's atomic replacement there can be a tiny window
    // where the file is empty/partial; retaining the previous palette avoids
    // flashing to the hardcoded fallback colors.
    if (matched >= 4 && next.background && next.text && next.accent)
      root.matugenColors = next
  }

  readonly property color matugenBackground: colorFromValue(matugenColors.background, Qt.rgba(0, 0, 0, 1))
  readonly property color matugenText: colorFromValue(matugenColors.text, Qt.rgba(1, 1, 1, 1))
  readonly property color matugenSurface: colorFromValue(matugenColors.surface, matugenBackground)
  readonly property color matugenSurfaceAlt: colorFromValue(matugenColors.surfaceAlt, matugenSurface)
  readonly property color matugenTextMuted: colorFromValue(matugenColors.textMuted, matugenText)
  readonly property color matugenAccent: colorFromValue(matugenColors.accent, matugenText)
  readonly property color matugenAccentText: colorFromValue(matugenColors.accentText, matugenBackground)
  readonly property color matugenAccentSoft: colorFromValue(matugenColors.accentSoft, matugenSurfaceAlt)
  readonly property color matugenSecondary: colorFromValue(matugenColors.secondary, matugenAccent)
  readonly property color matugenTertiary: colorFromValue(matugenColors.tertiary, matugenAccent)
  readonly property color matugenOutline: colorFromValue(matugenColors.outline, matugenTextMuted)
  readonly property color matugenError: colorFromValue(matugenColors.error, Qt.rgba(1, 0.3, 0.3, 1))

  // Foundational roles consumed throughout Commons/Ui and by bar widgets.
  readonly property color foreground: matugenText
  readonly property color background: matugenBackground
  readonly property color accent: matugenAccent
  readonly property color urgent: matugenError
  readonly property color muted: matugenTextMuted

  // Short aliases used by custom bar widgets. These all resolve to the same
  // Matugen source of truth, so a widget cannot accidentally fall back to a
  // second palette.
  readonly property color text: matugenText
  readonly property color surface: matugenSurface
  readonly property color surfaceAlt: matugenSurfaceAlt
  readonly property color textMuted: matugenTextMuted
  readonly property color accentText: matugenAccentText
  readonly property color accentSoft: matugenAccentSoft
  readonly property color secondary: matugenSecondary
  readonly property color tertiary: matugenTertiary
  readonly property color outline: matugenOutline
  readonly property color error: matugenError

  property var shellValues: ({})
  property var themeShellValues: ({})
  property var userShellValues: ({})

  function pick(key, fallback) {
    var v = shellValues[key]
    return (typeof v === "string" && v.length > 0) ? v : fallback
  }

  function pickAlpha(key, fallback) {
    var v = shellValues[key]
    if (typeof v !== "string" || v.length === 0) return fallback
    var n = Number(v)
    if (!isFinite(n)) return fallback
    return Math.max(0, Math.min(1, n))
  }

  function firstColorToken(value) {
    var parts = String(value || "").replace(/^\s+|\s+$/g, "").split(/\s+/)
    for (var i = 0; i < parts.length; i++) {
      if (!parts[i].match(/^-?\d+(?:\.\d+)?deg$/)) return parts[i]
    }
    return value
  }

  function flatColor(value, fallback) {
    var token = firstColorToken(value)
    var role = String(token || "").replace(/^\s+|\s+$/g, "").toLowerCase()
    if (role === "foreground" || role === "text") return root.foreground
    if (role === "accent") return root.accent
    if (role === "urgent" || role === "error") return root.urgent
    if (role === "muted") return root.muted
    if (role === "background") return root.background
    if (role === "transparent") return Qt.rgba(0, 0, 0, 0)
    var color = Geometry.canonicalColor(token, 1)
    if (typeof color === "string" && color === token && token.charAt(0) !== "#") return fallback
    return color
  }

  function composed(colorKey, alphaKey, colorFallback, alphaFallback) {
    return Util.alpha(flatColor(pick(colorKey, colorFallback), colorFallback), pickAlpha(alphaKey, alphaFallback))
  }

  // Explicit Matugen mapping for all reusable Omarchy surfaces. Applets and
  // popups inherit these through Color.*, so there is no separate theme layer
  // fighting Matugen.
  readonly property QtObject bar: QtObject {
    readonly property color background: root.matugenBackground
    readonly property color text: root.matugenText
    readonly property color active: root.matugenAccent
  }

  readonly property QtObject popups: QtObject {
    readonly property color background: root.matugenSurface
    readonly property color text: root.matugenText
    readonly property color border: root.matugenOutline
  }

  readonly property QtObject tooltip: QtObject {
    readonly property color background: root.matugenSurfaceAlt
    readonly property color text: root.matugenText
    readonly property color border: root.matugenOutline
  }

  readonly property QtObject notifications: QtObject {
    readonly property color background: root.matugenSurface
    readonly property color text: root.matugenText
    readonly property color border: root.matugenOutline
    readonly property color countdown: root.matugenAccent
  }

  readonly property QtObject menu: QtObject {
    readonly property color background: root.matugenSurface
    readonly property color text: root.matugenText
    readonly property color border: root.matugenOutline
    readonly property color scrim: Util.alpha(root.matugenBackground, 0.5)
    readonly property color selectedBackground: Util.alpha(root.matugenAccentSoft, 0.55)
    readonly property color selectedText: root.matugenAccentText
    readonly property color selectedBorder: root.matugenOutline
  }

  readonly property QtObject polkit: QtObject {
    readonly property color background: root.matugenSurface
    readonly property color text: root.matugenText
    readonly property color textError: root.matugenError
    readonly property color border: root.matugenOutline
    readonly property color borderError: root.matugenError
    readonly property color accent: root.matugenAccent
    readonly property color scrim: Util.alpha(root.matugenBackground, 0.5)
  }

  readonly property QtObject lock: QtObject {
    readonly property color background: Util.alpha(root.matugenBackground, 0.94)
    readonly property color text: root.matugenText
    readonly property color placeholder: root.matugenTextMuted
    readonly property color textError: root.matugenError
    readonly property color border: root.matugenOutline
    readonly property color borderActive: root.matugenAccent
    readonly property color borderError: root.matugenError
    readonly property color selection: Util.alpha(root.matugenAccentSoft, 0.45)
  }

  readonly property QtObject imagePicker: QtObject {
    readonly property color scrim: Util.alpha(root.matugenBackground, 0.5)
    readonly property color text: root.matugenText
    readonly property color selectedBorder: root.matugenAccent
    readonly property color unselectedBorder: Util.alpha(root.matugenOutline, 0.28)
  }

  // Keep the shell.toml parser for typography/spacing and any non-color style
  // options. Matugen owns the actual palette regardless of those files.
  function loadColors(raw) {
  }

  function parseShell(raw) {
    var parsed = {}
    var lines = String(raw || "").split("\n")
    var section = ""
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].replace(/^\s+|\s+$/g, "")
      if (!line || line.charAt(0) === "#") continue
      var sectionMatch = line.match(/^\[([A-Za-z0-9_-]+)\]\s*(#.*)?$/)
      if (sectionMatch) { section = sectionMatch[1]; continue }
      var stringKv = line.match(/^([A-Za-z0-9_-]+)\s*=\s*["']([^"']+)["']\s*(#.*)?$/)
      var numKv = line.match(/^([A-Za-z0-9_-]+)\s*=\s*(-?\d+(?:\.\d+)?)\s*(#.*)?$/)
      var bareKv = line.match(/^([A-Za-z0-9_-]+)\s*=\s*([A-Za-z][A-Za-z0-9_-]*)\s*(#.*)?$/)
      var kv = stringKv || numKv || bareKv
      if (!kv || !section) continue
      parsed[section + "." + kv[1]] = kv[2]
    }
    return parsed
  }

  function mergeShell() {
    var merged = {}
    for (var tk in themeShellValues) merged[tk] = themeShellValues[tk]
    for (var uk in userShellValues) merged[uk] = userShellValues[uk]
    shellValues = merged
    Style.applyShellValues(merged)
  }

  function loadShell(raw) {
    themeShellValues = parseShell(raw)
    mergeShell()
  }

  function loadUserShell(raw) {
    userShellValues = parseShell(raw)
    mergeShell()
  }

  // Poll rather than attaching a filesystem callback to the generated QML.
  // Matugen replaces Theme.qml atomically, and polling avoids a rapid
  // change->reload callback loop in Quickshell while still tracking updates.
  property Timer matugenPoll: Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.matugenThemeFile.reload()
  }

  property FileView matugenThemeFile: FileView {
    path: root.matugenThemePath
    watchChanges: false
    printErrors: false
    onLoaded: root.parseMatugen(text())
  }

  property FileView shellFile: FileView {
    id: shellFile
    path: root.currentThemePath + "/shell.toml"
    watchChanges: false
    printErrors: false
    onLoaded: root.loadShell(text())
    onLoadFailed: root.loadShell("")
  }

  property FileView userShellFile: FileView {
    id: userShellFile
    path: root.home + "/.config/omarchy/shell.toml"
    watchChanges: true
    printErrors: false
    onLoaded: root.loadUserShell(text())
    onFileChanged: reload()
    onLoadFailed: root.loadUserShell("")
  }

  Component.onCompleted: {
    matugenThemeFile.reload()
    shellFile.reload()
    userShellFile.reload()
  }
}
