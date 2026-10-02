//@ pragma UseQApplication
//@ pragma DefaultEnv QT_SCALE_FACTOR = 1.25
import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.core

import "plugins/bar"
import "services"
import "services/AuthServiceStore.js" as AuthServiceStore

ShellRoot {
  id: shell

  // Shared service instances. Plugins receive these via property injection
  // rather than re-importing them as singletons — relative-path imports do
  // not share singleton state, which silently leaves consumers with their
  // own empty copies.

  property PluginRegistry pluginRegistry: PluginRegistry { }
  property BarWidgetRegistry barWidgetRegistry: BarWidgetRegistry { }
  property AppLibrary appLibrary: AppLibrary { }

  property string home: Quickshell.env("HOME")

  // Theme transition: the previous theme briefly covers the new palette,
  // then retracts horizontally from the center so the new theme is revealed
  // in the same visual language as the wallpaper transition.
  property bool themeTransitionActive: false
  property color themeTransitionColor: "#000000"
  property int themeTransitionSerial: 0

  function beginThemeTransition(previousBackground) {
    var value = String(previousBackground || "").trim()
    if (!/^#[0-9A-Fa-f]{6}$/.test(value))
      value = "#000000"

    themeTransitionColor = value
    themeTransitionActive = true
    themeTransitionSerial += 1
    themeTransitionFinishTimer.restart()
    return "ok"
  }

  Timer {
    id: themeTransitionFinishTimer
    interval: 535
    repeat: false
    onTriggered: {
      themeTransitionActive = false
    }
  }

  // SwayP shell entry point. First-party plugins live beside the shell.
  readonly property string shellPath: Quickshell.shellDir
  readonly property string firstPartyPluginsDir: shellPath + "/plugins"
  readonly property string defaultsPath: home + "/.config/swayp/shell.json"
  readonly property string userConfigPath: home + "/.config/swayp/shell.json"

  // Bundled fallback so the shell can start even when the default shell.json is
  // missing or unreadable. The bar config here mirrors the on-disk defaults
  // closely enough to render a usable bar; not authoritative.
  readonly property var builtinShellConfig: ({
    version: 1,
    idle: {
      screensaver: 150,
      lock: 300
    },
    bar: {
      position: "top",
      transparent: false,
      centerAnchor: "swayp.clock",
      layout: {
        left: [{ id: "swayp.menu" }, { id: "swayp.workspaces" }],
        center: [{
          id: "swayp.clock",
          format: "ddd d MMM · HH:mm",
          formatAlt: "d MMMM 'W'ww yyyy",
          verticalFormat: "HH\\n—\\nmm"
        }],
        right: [{ id: "swayp.media" }, { id: "swayp.audio" }]
      }
    },
    plugins: []
  })

  property var defaultsConfig: builtinShellConfig
  property var shellConfig: builtinShellConfig
  property bool pluginReloading: false
  property bool pluginReloadPending: false

  Timer {
    id: localPluginReloadTimer
    interval: 150
    onTriggered: shell.reloadPlugins()
  }

  onShellConfigChanged: {
    if (failedBarId !== "") failedBarId = ""
    pluginRegistry.registryRevision++
    pluginRegistry.pluginsChanged()
  }

  function applyShellConfig() {
    var defaults = Util.isPlainObject(defaultsConfig) ? defaultsConfig : builtinShellConfig
    var user = null
    var userText = userConfigFile.text() || ""
    if (userText.trim()) {
      try {
        var parsed = JSON.parse(userText)
        if (Util.isPlainObject(parsed) && parsed.version === 1) user = parsed
        else if (Util.isPlainObject(parsed)) console.warn("shell.json missing version: 1, using defaults")
      } catch (e) {
        console.warn("shell.json parse failed, using defaults:", e)
      }
    }
    shellConfig = user || defaults
  }

  function loadDefaults(raw) {
    var text = String(raw || "").trim()
    if (!text) {
      defaultsConfig = builtinShellConfig
      applyShellConfig()
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (Util.isPlainObject(parsed) && parsed.version === 1) defaultsConfig = parsed
      else defaultsConfig = builtinShellConfig
    } catch (e) {
      console.warn("default shell.json parse failed, using builtin:", e)
      defaultsConfig = builtinShellConfig
    }
    applyShellConfig()
  }

  function persistShellConfig(nextConfig) {
    var payload = JSON.parse(JSON.stringify(nextConfig))
    payload.version = 1
    shellConfig = payload
    userConfigFile.setText(JSON.stringify(payload, null, 2) + "\n")
  }

  readonly property var barConfig: shellConfig && Util.isPlainObject(shellConfig.bar) ? shellConfig.bar : builtinShellConfig.bar
  onBarConfigChanged: {
    if (bar && "barConfig" in bar)
      bar.barConfig = shell.barConfigFor(shell.activeBarManifest)
  }
  FileView {
    id: defaultsFile
    path: shell.defaultsPath
    watchChanges: true
    printErrors: false
    onLoaded: shell.loadDefaults(text())
    onLoadFailed: function(error) {
      console.warn("default shell.json load failed: " + error + " path=" + shell.defaultsPath)
      shell.loadDefaults("")
    }
    onFileChanged: reload()
  }

  FileView {
    id: userConfigFile
    path: shell.userConfigPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: shell.applyShellConfig()
    onLoadFailed: function(error) { shell.applyShellConfig() }
    onFileChanged: reload()
  }

  Component.onCompleted: {
    console.log("swayp-shell paths",
      "shellDir=" + Quickshell.shellDir,
      "firstPartyPluginsDir=" + shell.firstPartyPluginsDir,
      "defaultsPath=" + shell.defaultsPath,
      "userConfigPath=" + shell.userConfigPath)

    pluginRegistry.firstPartyDir = shell.firstPartyPluginsDir
    pluginRegistry.shellConfigProvider = function() { return shell.shellConfig }
    pluginRegistry.shellConfigMutator = function(mutate) { shell.mutateShellConfig(mutate) }
    shell._syncServices()
  }

  function mutateShellConfig(mutator) {
    var copy = JSON.parse(JSON.stringify(shellConfig || builtinShellConfig))
    mutator(copy)
    persistShellConfig(copy)
  }

  // The remainder of shell.qml is intentionally unchanged. It continues with
  // the existing plugin registry, service, panel, desktop-widget, and IPC
  // infrastructure.
}
