pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "BorderGeometry.js" as Geometry

// SwayP color system for Sway + Quickshell.
// The active static theme is the single palette authority.
QtObject {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateHome: home + "/.local/state"
  readonly property string currentThemePath: stateHome + "/swayp/current/theme"
  readonly property string palettePath: stateHome + "/swayp/current/palette.json"

  property var paletteColors: []
  property var semanticColors: ({})
  property bool paletteValid: false
  // Shared timing signal for theme palette changes. The palette duration is kept
  // identical to the wallpaper fade, including a linear progress curve, so both visual layers track together frame-for-frame.
  property bool themeTransitionActive: false
  property real themeTransitionProgress: 1
  property var transitionFrom: ({})

  function colorFromValue(value, fallback) {
    if (typeof value !== "string" || !/^#[0-9A-Fa-f]{6}$/.test(value))
      return fallback
    var r = parseInt(value.slice(1, 3), 16) / 255
    var g = parseInt(value.slice(3, 5), 16) / 255
    var b = parseInt(value.slice(5, 7), 16) / 255
    return Qt.rgba(r, g, b, 1)
  }

  function animatedColor(key, target) {
    if (!root.themeTransitionActive || transitionFrom[key] === undefined)
      return target
    return root.mix(transitionFrom[key], target, root.themeTransitionProgress)
  }

  function parsePalette(raw) {
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

    var animate = root.paletteValid
    if (animate) {
      root.transitionFrom = {
        background: root.themeBackground,
        foreground: root.themeForeground,
        red: root.themeRed,
        green: root.themeGreen,
        yellow: root.themeYellow,
        blue: root.themeBlue,
        magenta: root.themeMagenta,
        cyan: root.themeCyan,
        brightForeground: root.themeBrightForeground,
        darkBackground: root.themeDarkBackground,
        darkerBackground: root.themeDarkerBackground,
        lighterBackground: root.themeLighterBackground,
        accent: root.themeAccent,
        selection: root.themeSelection
      }
      root.themeTransitionProgress = 0
      root.themeTransitionActive = true
    }

    root.paletteColors = colors
    root.semanticColors = parsed && parsed.semantic && typeof parsed.semantic === "object"
      ? parsed.semantic : ({})
    root.paletteValid = true

    if (animate)
      themeTransitionAnimation.restart()
  }

  function semanticValue(key, fallback) {
    var value = semanticColors[key]
    return typeof value === "string" && /^#[0-9A-Fa-f]{6}$/.test(value) ? value : fallback
  }

  readonly property color themeBackground: animatedColor("background", paletteValid ? colorFromValue(semanticValue("background", paletteColors[0]), Qt.rgba(0.07, 0.07, 0.07, 1)) : Qt.rgba(0.07, 0.07, 0.07, 1))
  readonly property color themeForeground: animatedColor("foreground", paletteValid ? colorFromValue(semanticValue("foreground", paletteColors[7]), Qt.rgba(1, 1, 1, 1)) : Qt.rgba(1, 1, 1, 1))
  readonly property color themeMuted: themeForeground
  readonly property color themeRed: animatedColor("red", paletteValid ? colorFromValue(paletteColors[1], Qt.rgba(1, 0.33, 0.33, 1)) : Qt.rgba(1, 0.33, 0.33, 1))
  readonly property color themeGreen: animatedColor("green", paletteValid ? colorFromValue(paletteColors[2], Qt.rgba(0.31, 0.98, 0.48, 1)) : Qt.rgba(0.31, 0.98, 0.48, 1))
  readonly property color themeYellow: animatedColor("yellow", paletteValid ? colorFromValue(paletteColors[3], Qt.rgba(0.95, 0.85, 0.30, 1)) : Qt.rgba(0.95, 0.85, 0.30, 1))
  readonly property color themeBlue: animatedColor("blue", paletteValid ? colorFromValue(paletteColors[4], Qt.rgba(0.35, 0.65, 1, 1)) : Qt.rgba(0.35, 0.65, 1, 1))
  readonly property color themeMagenta: animatedColor("magenta", paletteValid ? colorFromValue(paletteColors[5], Qt.rgba(0.9, 0.45, 0.9, 1)) : Qt.rgba(0.9, 0.45, 0.9, 1))
  readonly property color themeCyan: animatedColor("cyan", paletteValid ? colorFromValue(paletteColors[6], Qt.rgba(0.2, 0.85, 0.75, 1)) : Qt.rgba(0.2, 0.85, 0.75, 1))
  readonly property color themeBrightForeground: animatedColor("brightForeground", paletteValid ? colorFromValue(semanticValue("bright_foreground", paletteColors[15]), Qt.rgba(1, 1, 1, 1)) : Qt.rgba(1, 1, 1, 1))
  readonly property color themeDarkBackground: animatedColor("darkBackground", paletteValid ? colorFromValue(semanticValue("dark_background", paletteColors[0]), themeBackground) : themeBackground)
  readonly property color themeDarkerBackground: animatedColor("darkerBackground", paletteValid ? colorFromValue(semanticValue("darker_background", paletteColors[0]), themeBackground) : themeBackground)
  readonly property color themeLighterBackground: animatedColor("lighterBackground", paletteValid ? colorFromValue(semanticValue("lighter_background", paletteColors[0]), themeBackground) : themeBackground)
  readonly property color themeLightForeground: themeForeground

  // The theme's own accent remains authoritative; do not derive or replace it.
  readonly property color themeAccent: animatedColor("accent", paletteValid ? colorFromValue(semanticValue("accent", themeBlue), themeBlue) : themeBlue)
  readonly property color themeSelection: animatedColor("selection", paletteValid ? colorFromValue(semanticValue("selection", paletteColors[4]), themeBlue) : themeBlue)

  function mix(first, second, amount) {
    var t = Math.max(0, Math.min(1, Number(amount)))
    return Qt.rgba(
      first.r * (1 - t) + second.r * t,
      first.g * (1 - t) + second.g * t,
      first.b * (1 - t) + second.b * t,
      1)
  }

  readonly property color themeTint: mix(themeGreen, themeCyan, 0.50)
  readonly property color themeBackgroundDeep: themeDarkerBackground
  readonly property color themeSurfaceTinted: themeLighterBackground
  readonly property color themeSurfaceAltTinted: themeLighterBackground
  readonly property color themeElevatedTinted: themeLighterBackground

  // The bar keeps the same surface as Sway's tabs. Normal applets use the
  // same foreground as the clock; accent is reserved for active/hover states.
  readonly property color themeBarBackground: themeLighterBackground
  readonly property color themeBarForeground: themeForeground
  readonly property color themeBarPassive: themeForeground

  readonly property real shellOpacity: 0.97

  readonly property color foreground: themeForeground
  readonly property color background: Util.alpha(themeBackground, root.shellOpacity)
  readonly property color accent: themeAccent
  readonly property color urgent: themeRed
  readonly property color muted: themeMuted

  readonly property color backgroundDeep: Util.alpha(themeBackgroundDeep, root.shellOpacity)
  readonly property color backgroundRaised: Util.alpha(themeSurfaceTinted, root.shellOpacity)
  readonly property color backgroundElevated: Util.alpha(themeElevatedTinted, root.shellOpacity)

  readonly property color text: themeForeground
  readonly property color surface: Util.alpha(themeSurfaceTinted, root.shellOpacity)
  readonly property color surfaceAlt: Util.alpha(themeSurfaceAltTinted, root.shellOpacity)
  readonly property color textMuted: themeMuted
  readonly property color accentText: themeBackground
  readonly property color accentSoft: Util.alpha(themeAccent, 0.22)
  readonly property color secondary: themeBlue
  readonly property color secondarySoft: Util.alpha(themeBlue, 0.26)
  readonly property color tertiary: themeMagenta
  readonly property color tertiarySoft: Util.alpha(themeMagenta, 0.22)
  readonly property color success: themeGreen
  readonly property color warning: themeYellow
  readonly property color info: themeCyan
  readonly property color outline: themeMuted
  readonly property color outlineStrong: themeLightForeground
  readonly property color divider: Util.alpha(themeForeground, 0.16)
  readonly property color hover: Util.alpha(themeAccent, 0.16)
  readonly property color active: Util.alpha(themeAccent, 0.24)
  readonly property color selection: Util.alpha(themeSelection, 0.30)
  readonly property color error: themeRed

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

  readonly property QtObject bar: QtObject {
    readonly property color background: Util.alpha(root.themeBarBackground, root.shellOpacity)
    // One shared passive color for every normal bar element.
    readonly property color text: root.themeBarPassive
    readonly property color active: root.accent
  }

  // Shared interactive control language used by popup, menu, clipboard,
  // session and other interactive surfaces. Components own layout; these roles
  // keep hover/active/selected states visually consistent across SwayP.
  // Brand identity roles: one source of truth for every SwayP mark.
  readonly property QtObject brand: QtObject {
    readonly property color accent: root.accent
    readonly property color highlight: root.foreground
    readonly property color depth: root.active
  }

  readonly property QtObject controls: QtObject {
    readonly property color background: root.surfaceAlt
    readonly property color hoverBackground: root.hover
    readonly property color activeBackground: root.active
    readonly property color selectedBackground: root.accent
    readonly property color text: root.foreground
    readonly property color selectedText: root.foreground
    readonly property color border: Util.alpha(root.foreground, 0.18)
    readonly property color selectedBorder: root.foreground
    readonly property color disabledText: Util.alpha(root.foreground, 0.40)
    readonly property color danger: root.error
  }

  readonly property QtObject popups: QtObject {
    readonly property color background: root.surface
    readonly property color text: root.foreground
    readonly property color border: root.foreground
  }

  readonly property QtObject tooltip: QtObject {
    readonly property color background: root.popups.background
    readonly property color text: root.foreground
    readonly property color border: root.foreground
  }

  readonly property QtObject notifications: QtObject {
    readonly property color background: root.popups.background
    readonly property color text: root.foreground
    readonly property color border: root.foreground
    readonly property color countdown: root.controls.text
  }

  readonly property QtObject menu: QtObject {
    readonly property color background: root.popups.background
    readonly property color text: root.foreground
    readonly property color border: root.foreground
    readonly property color scrim: Util.alpha(root.backgroundDeep, 0.38)
    readonly property color selectedBackground: root.controls.selectedBackground
    readonly property color selectedText: root.controls.selectedText
    readonly property color selectedBorder: root.controls.selectedBorder
  }

  readonly property QtObject polkit: QtObject {
    readonly property color background: root.popups.background
    readonly property color text: root.foreground
    readonly property color textError: root.error
    readonly property color border: root.foreground
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
    readonly property color borderActive: root.foreground
    readonly property color borderError: root.error
    readonly property color selection: root.foreground
  }

  // Shared visual language for fullscreen experiences. Components may keep
  // their own layout and compositing strength, but the underlying palette roles
  // stay consistent with normal SwayP surfaces and states.
  readonly property QtObject fullscreen: QtObject {
    readonly property color background: root.surface
    readonly property color text: root.foreground
    readonly property color border: root.foreground
    readonly property color scrim: root.backgroundDeep
    readonly property color selectedBorder: root.foreground
    readonly property color unselectedBorder: root.foreground
  }

  function loadColors(raw) {
    root.parsePalette(raw)
  }

  function parseShell(raw) {
    var parsed = {}
    var lines = String(raw || "").split("
")
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

  property NumberAnimation themeTransitionAnimation: NumberAnimation {
    id: themeTransitionAnimation
    target: root
    property: "themeTransitionProgress"
    from: 0
    to: 1
    duration: 500
    easing.type: Easing.Linear
    onFinished: {
      root.themeTransitionProgress = 1
      root.themeTransitionActive = false
    }
  }

  property FileView paletteFile: FileView {
    path: root.palettePath
    watchChanges: true
    printErrors: false
    onLoaded: root.parsePalette(text())
    onFileChanged: reload()
    onLoadFailed: root.paletteValid = false
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
    paletteFile.reload()
    shellFile.reload()
    userShellFile.reload()
  }
}
