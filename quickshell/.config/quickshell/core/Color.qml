pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "BorderGeometry.js" as Geometry

// SwayP color system for Sway + Quickshell.
//
// Aether is the visual palette authority. Matugen remains loaded as a
// compatibility fallback for external templates and older generated files.
// The shell deliberately tints even its darkest surfaces from Aether so the
// wallpaper palette is visible across the whole UI instead of producing a
// black/gray shell with colored icons.
QtObject {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateHome: home + "/.local/state"
  readonly property string currentThemePath: stateHome + "/swayp/current/theme"
  readonly property string matugenThemePath: home + "/.config/quickshell/generated/Theme.qml"
  readonly property string aetherPalettePath: stateHome + "/swayp/current/aether-palette.json"

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
  property var aetherColors: []
  property bool aetherPaletteValid: false

  function parseAether(raw) {
    var parsed
    try {
      parsed = JSON.parse(String(raw || ""))
    } catch (e) {
      return
    }

    var colors = parsed && parsed.colors
    if (!Array.isArray(colors) || colors.length !== 16) return

    for (var i = 0; i < colors.length; i++) {
      if (typeof colors[i] !== "string" || !/^#[0-9A-Fa-f]{6}$/.test(colors[i])) return
    }

    root.aetherColors = colors
    root.aetherPaletteValid = true
  }

  readonly property color aetherBackground: aetherPaletteValid ? colorFromValue(aetherColors[0], matugenBackground) : matugenBackground
  readonly property color aetherForeground: aetherPaletteValid ? colorFromValue(aetherColors[7], matugenText) : matugenText
  readonly property color aetherMuted: aetherPaletteValid ? colorFromValue(aetherColors[8], matugenTextMuted) : matugenTextMuted
  readonly property color aetherRed: aetherPaletteValid ? colorFromValue(aetherColors[1], matugenError) : matugenError
  readonly property color aetherGreen: aetherPaletteValid ? colorFromValue(aetherColors[2], matugenAccent) : matugenAccent
  readonly property color aetherYellow: aetherPaletteValid ? colorFromValue(aetherColors[3], matugenAccent) : matugenAccent
  readonly property color aetherBlue: aetherPaletteValid ? colorFromValue(aetherColors[4], matugenAccent) : matugenAccent
  readonly property color aetherMagenta: aetherPaletteValid ? colorFromValue(aetherColors[5], matugenAccent) : matugenAccent
  readonly property color aetherCyan: aetherPaletteValid ? colorFromValue(aetherColors[6], matugenAccent) : matugenAccent
  readonly property color aetherBrightForeground: aetherPaletteValid ? colorFromValue(aetherColors[15], matugenText) : matugenText

  // Blend helpers keep the 16-color Aether palette expressive without
  // hard-coding wallpaper-specific RGB values. The ANSI colors become the
  // source for a family of dark, tinted surfaces.
  function mix(first, second, amount) {
    var t = Math.max(0, Math.min(1, Number(amount)))
    return Qt.rgba(
      first.r * (1 - t) + second.r * t,
      first.g * (1 - t) + second.g * t,
      first.b * (1 - t) + second.b * t,
      1)
  }

  readonly property color aetherTint: mix(aetherGreen, aetherCyan, 0.50)
  readonly property color aetherBackgroundTinted: mix(aetherBackground, aetherTint, 0.14)
  readonly property color aetherBackgroundDeep: mix(aetherBackground, aetherTint, 0.10)
  readonly property color aetherSurfaceTinted: mix(aetherBackground, aetherTint, 0.18)
  readonly property color aetherSurfaceAltTinted: mix(aetherBackground, aetherTint, 0.22)
  readonly property color aetherElevatedTinted: mix(aetherBackground, aetherTint, 0.26)

  readonly property color matugenError: colorFromValue(matugenColors.error, Qt.rgba(1, 0.3, 0.3, 1))

  // Foundational roles consumed throughout Commons/Ui and by bar widgets.
  readonly property color foreground: aetherForeground
  readonly property color background: Util.alpha(aetherBackgroundTinted, 0.97)
  readonly property color accent: aetherCyan
  readonly property color urgent: aetherRed
  readonly property color muted: aetherMuted

  // Semantic surfaces are intentionally opaque and visibly tinted. This is
  // what makes the bar, popups and menus feel like one wallpaper-derived UI.
  readonly property color backgroundDeep: Util.alpha(aetherBackgroundDeep, 0.97)
  readonly property color backgroundRaised: Util.alpha(aetherSurfaceTinted, 0.97)
  readonly property color backgroundElevated: Util.alpha(aetherElevatedTinted, 0.97)

  readonly property color text: aetherForeground
  readonly property color surface: Util.alpha(aetherSurfaceTinted, 0.93)
  readonly property color surfaceAlt: Util.alpha(aetherSurfaceAltTinted, 0.93)
  readonly property color textMuted: aetherMuted
  readonly property color accentText: aetherBackgroundDeep
  readonly property color accentSoft: Util.alpha(aetherCyan, 0.30)
  readonly property color secondary: aetherBlue
  readonly property color secondarySoft: Util.alpha(aetherBlue, 0.26)
  readonly property color tertiary: aetherMagenta
  readonly property color tertiarySoft: Util.alpha(aetherMagenta, 0.22)
  readonly property color success: aetherGreen
  readonly property color warning: aetherYellow
  readonly property color info: aetherCyan
  readonly property color outline: mix(aetherForeground, aetherTint, 0.34)
  readonly property color outlineStrong: mix(aetherForeground, aetherTint, 0.50)
  readonly property color divider: Util.alpha(aetherForeground, 0.16)
  readonly property color hover: Util.alpha(aetherCyan, 0.22)
  readonly property color active: Util.alpha(aetherGreen, 0.30)
  readonly property color selection: Util.alpha(aetherBlue, 0.34)
  readonly property color error: aetherRed

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

  // Reusable surfaces all inherit the same Aether-derived tint.
  readonly property QtObject bar: QtObject {
    readonly property color background: root.backgroundDeep
    readonly property color text: root.text
    readonly property color active: root.accent
  }

  readonly property QtObject popups: QtObject {
    readonly property color background: root.surface
    readonly property color text: root.text
    readonly property color border: root.outline
  }

  readonly property QtObject tooltip: QtObject {
    readonly property color background: root.surfaceAlt
    readonly property color text: root.text
    readonly property color border: root.outline
  }

  readonly property QtObject notifications: QtObject {
    readonly property color background: root.surface
    readonly property color text: root.text
    readonly property color border: root.outline
    readonly property color countdown: root.accent
  }

  readonly property QtObject menu: QtObject {
    readonly property color background: root.surface
    readonly property color text: root.text
    readonly property color border: root.outline
    readonly property color scrim: Util.alpha(root.backgroundDeep, 0.72)
    readonly property color selectedBackground: root.selection
    readonly property color selectedText: root.text
    readonly property color selectedBorder: root.accent
  }

  readonly property QtObject polkit: QtObject {
    readonly property color background: root.surface
    readonly property color text: root.text
    readonly property color textError: root.error
    readonly property color border: root.outline
    readonly property color borderError: root.error
    readonly property color accent: root.accent
    readonly property color scrim: Util.alpha(root.backgroundDeep, 0.72)
  }

  readonly property QtObject lock: QtObject {
    readonly property color background: Util.alpha(root.backgroundDeep, 0.96)
    readonly property color text: root.text
    readonly property color placeholder: root.textMuted
    readonly property color textError: root.error
    readonly property color border: root.outline
    readonly property color borderActive: root.accent
    readonly property color borderError: root.error
    readonly property color selection: root.selection
  }

  readonly property QtObject imagePicker: QtObject {
    readonly property color scrim: Util.alpha(root.backgroundDeep, 0.72)
    readonly property color text: root.text
    readonly property color selectedBorder: root.accent
    readonly property color unselectedBorder: Util.alpha(root.outline, 0.45)
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

  property FileView aetherPaletteFile: FileView {
    path: root.aetherPalettePath
    watchChanges: true
    printErrors: false
    onLoaded: root.parseAether(text())
    onFileChanged: reload()
    onLoadFailed: root.aetherPaletteValid = false
  }

  // When the Aether editor is open, mirror its live palette directly through
  // the Aether IPC-backed CLI. This means slider/color changes in the GUI are
  // reflected in SwayP without requiring "Apply Theme" or a shell restart.
  property Process aetherStatusProc: Process {
    id: aetherStatusProc
    command: ["aether", "status", "--json"]
    running: false

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "")
        if (!raw) return
        try {
          var parsed = JSON.parse(raw)
          if (parsed && Array.isArray(parsed.palette) && parsed.palette.length === 16) {
            root.parseAether(JSON.stringify({
              colors: parsed.palette
            }))
          }
        } catch (e) {
          // Aether is optional at runtime; keep the last valid palette when
          // the GUI is closed or its IPC socket is unavailable.
        }
      }
    }
  }

  property Timer aetherLivePoll: Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: {
      if (!aetherStatusProc.running)
        aetherStatusProc.running = true
    }
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
    path: root.home + "/.config/swayp/shell.toml"
    watchChanges: true
    printErrors: false
    onLoaded: root.loadUserShell(text())
    onFileChanged: reload()
    onLoadFailed: root.loadUserShell("")
  }

  Component.onCompleted: {
    aetherPaletteFile.reload()
    matugenThemeFile.reload()
    shellFile.reload()
    userShellFile.reload()
  }
}
