pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "BorderGeometry.js" as Geometry

// SwayP color system for Sway + Quickshell.
//
// Aether is the sole visual palette authority.
// The shell deliberately tints even its darkest surfaces from Aether so the
// wallpaper palette is visible across the whole UI instead of producing a
// black/gray shell with colored icons.
QtObject {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateHome: home + "/.local/state"
  readonly property string currentThemePath: stateHome + "/swayp/current/theme"
  readonly property string aetherPalettePath: stateHome + "/swayp/current/aether-palette.json"
  readonly property string paletteSourcePath: stateHome + "/swayp/current/palette-source"

  property string paletteSource: "aether"
  property var aetherColors: []
  property var semanticColors: ({})
  property bool aetherPaletteValid: false

  function colorFromValue(value, fallback) {
    if (typeof value !== "string" || !/^#[0-9A-Fa-f]{6}$/.test(value))
      return fallback

    var r = parseInt(value.slice(1, 3), 16) / 255
    var g = parseInt(value.slice(3, 5), 16) / 255
    var b = parseInt(value.slice(5, 7), 16) / 255
    return Qt.rgba(r, g, b, 1)
  }

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
    root.semanticColors = parsed && parsed.semantic && typeof parsed.semantic === "object"
      ? parsed.semantic : ({})
    root.aetherPaletteValid = true
  }

  function semanticValue(key, fallback) {
    var value = semanticColors[key]
    return typeof value === "string" && /^#[0-9A-Fa-f]{6}$/.test(value) ? value : fallback
  }

  // The static theme path carries semantic roles alongside the ANSI palette.
  // Aether/live palettes fall back to the traditional ANSI slots.
  readonly property color aetherBackground: aetherPaletteValid ? colorFromValue(semanticValue("background", aetherColors[0]), Qt.rgba(0.07, 0.07, 0.07, 1)) : Qt.rgba(0.07, 0.07, 0.07, 1)
  readonly property color aetherForeground: aetherPaletteValid ? colorFromValue(semanticValue("foreground", aetherColors[7]), Qt.rgba(1, 1, 1, 1)) : Qt.rgba(1, 1, 1, 1)
  readonly property color aetherMuted: aetherPaletteValid ? colorFromValue(semanticValue("muted", aetherColors[8]), Qt.rgba(0.62, 0.62, 0.62, 1)) : Qt.rgba(0.62, 0.62, 0.62, 1)
  readonly property color aetherRed: aetherPaletteValid ? colorFromValue(aetherColors[1], Qt.rgba(1, 0.33, 0.33, 1)) : Qt.rgba(1, 0.33, 0.33, 1)
  readonly property color aetherGreen: aetherPaletteValid ? colorFromValue(aetherColors[2], Qt.rgba(0.31, 0.98, 0.48, 1)) : Qt.rgba(0.31, 0.98, 0.48, 1)
  readonly property color aetherYellow: aetherPaletteValid ? colorFromValue(aetherColors[3], Qt.rgba(0.95, 0.85, 0.30, 1)) : Qt.rgba(0.95, 0.85, 0.30, 1)
  readonly property color aetherBlue: aetherPaletteValid ? colorFromValue(aetherColors[4], Qt.rgba(0.35, 0.65, 1, 1)) : Qt.rgba(0.35, 0.65, 1, 1)
  readonly property color aetherMagenta: aetherPaletteValid ? colorFromValue(aetherColors[5], Qt.rgba(0.9, 0.45, 0.9, 1)) : Qt.rgba(0.9, 0.45, 0.9, 1)
  readonly property color aetherCyan: aetherPaletteValid ? colorFromValue(aetherColors[6], Qt.rgba(0.2, 0.85, 0.75, 1)) : Qt.rgba(0.2, 0.85, 0.75, 1)
  readonly property color aetherBrightForeground: aetherPaletteValid ? colorFromValue(semanticValue("bright_foreground", aetherColors[15]), Qt.rgba(1, 1, 1, 1)) : Qt.rgba(1, 1, 1, 1)
  readonly property color aetherDarkBackground: aetherPaletteValid ? colorFromValue(semanticValue("dark_background", aetherColors[0]), aetherBackground) : aetherBackground
  readonly property color aetherDarkerBackground: aetherPaletteValid ? colorFromValue(semanticValue("darker_background", aetherColors[0]), aetherBackground) : aetherBackground
  readonly property color aetherLighterBackground: aetherPaletteValid ? colorFromValue(semanticValue("lighter_background", aetherColors[0]), aetherBackground) : aetherBackground
  readonly property color aetherLightForeground: aetherPaletteValid ? colorFromValue(semanticValue("light_foreground", aetherColors[7]), aetherForeground) : aetherForeground
  readonly property color aetherAccent: aetherPaletteValid ? colorFromValue(semanticValue("accent", aetherColors[6]), aetherCyan) : aetherCyan
  readonly property color aetherSelection: aetherPaletteValid ? colorFromValue(semanticValue("selection", aetherColors[4]), aetherBlue) : aetherBlue

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
  readonly property color aetherBackgroundTinted: aetherBackground
  readonly property color aetherBackgroundDeep: aetherDarkerBackground
  readonly property color aetherSurfaceTinted: aetherLighterBackground
  readonly property color aetherSurfaceAltTinted: mix(aetherLighterBackground, aetherLightForeground, 0.06)
  readonly property color aetherElevatedTinted: mix(aetherLighterBackground, aetherLightForeground, 0.12)


  // Single shell surface opacity. Change this one value to tune transparency everywhere.
  readonly property real shellOpacity: 0.97

  // Foundational roles consumed throughout Commons/Ui and by bar widgets.
  readonly property color foreground: aetherForeground
  readonly property color background: Util.alpha(aetherBackground, root.shellOpacity)
  readonly property color accent: aetherAccent
  readonly property color urgent: aetherRed
  readonly property color muted: aetherMuted

  // Popups use the exact same surface and opacity as the bar and Kitty.
  // There is intentionally no separate popup alpha: every shell surface
  // follows the single shellOpacity token below.
  readonly property color backgroundDeep: Util.alpha(aetherBackgroundDeep, root.shellOpacity)
  readonly property color backgroundRaised: Util.alpha(aetherSurfaceTinted, root.shellOpacity)
  readonly property color backgroundElevated: Util.alpha(aetherElevatedTinted, root.shellOpacity)

  readonly property color text: aetherForeground
  readonly property color surface: Util.alpha(aetherSurfaceTinted, root.shellOpacity)
  readonly property color surfaceAlt: Util.alpha(aetherSurfaceAltTinted, root.shellOpacity)
  readonly property color textMuted: aetherMuted
  readonly property color accentText: aetherBackground
  readonly property color accentSoft: Util.alpha(aetherAccent, 0.30)
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
  readonly property color hover: Util.alpha(aetherAccent, 0.22)
  readonly property color active: Util.alpha(aetherAccent, 0.30)
  readonly property color selection: Util.alpha(aetherSelection, 0.34)
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
    // The bar uses the theme's actual background; popups use the lighter surface.
    readonly property color background: root.background
    readonly property color text: root.text
    readonly property color active: root.accent
  }

  readonly property QtObject popups: QtObject {
    readonly property color background: root.surface
    readonly property color text: root.text
    readonly property color border: root.outline
  }

  readonly property QtObject tooltip: QtObject {
    readonly property color background: root.popups.background
    readonly property color text: root.text
    readonly property color border: root.outline
  }

  readonly property QtObject notifications: QtObject {
    readonly property color background: root.popups.background
    readonly property color text: root.text
    readonly property color border: root.outline
    readonly property color countdown: root.accent
  }

  readonly property QtObject menu: QtObject {
    readonly property color background: root.popups.background
    readonly property color text: root.text
    readonly property color border: root.outline
    readonly property color scrim: Util.alpha(root.backgroundDeep, 0.38)
    readonly property color selectedBackground: root.selection
    readonly property color selectedText: root.text
    readonly property color selectedBorder: root.accent
  }

  readonly property QtObject polkit: QtObject {
    readonly property color background: root.popups.background
    readonly property color text: root.text
    readonly property color textError: root.error
    readonly property color border: root.outline
    readonly property color borderError: root.error
    readonly property color accent: root.accent
    readonly property color scrim: Util.alpha(root.backgroundDeep, 0.72)
  }

  readonly property QtObject lock: QtObject {
    readonly property color background: Util.alpha(root.backgroundDeep, root.shellOpacity)
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

  // Keep the shell.toml parser for typography/spacing and user style options.
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

  property FileView paletteSourceFile: FileView {
    path: root.paletteSourcePath
    watchChanges: true
    printErrors: false
    onLoaded: {
      var value = String(text || "").trim()
      root.paletteSource = value === "theme" ? "theme" : "aether"
      root.aetherPaletteFile.reload()
    }
    onFileChanged: reload()
    onLoadFailed: {
      root.paletteSource = "aether"
      root.aetherPaletteFile.reload()
    }
  }

  property FileView aetherPaletteFile: FileView {
    path: root.aetherPalettePath
    watchChanges: true
    printErrors: false
    onLoaded: {
      if (root.paletteSource !== "theme") root.parseAether(text())
    }
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
          if (root.paletteSource !== "theme" && parsed && Array.isArray(parsed.palette) && parsed.palette.length === 16) {
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
    running: root.paletteSource !== "theme"
    triggeredOnStart: true
    onTriggered: {
      if (!aetherStatusProc.running)
        aetherStatusProc.running = true
    }
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
    shellFile.reload()
    userShellFile.reload()
  }
}
