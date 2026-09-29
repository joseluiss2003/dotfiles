import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
  id: root

  property var shell: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string stayAwakeStateDir: home + "/.local/state/swayp/indicators"
  readonly property string stayAwakeStatePath: stayAwakeStateDir + "/stay-awake"

  // Idle ownership belongs to swayidle. This service only exposes the
  // SwayP stay-awake state and a diagnostic view of compositor idle state.
  readonly property int lockTimeoutSeconds: 300
  readonly property int dpmsTimeoutSeconds: 600
  readonly property bool idleEnabled: stayAwakeStateLoaded && !stayAwake

  property bool stayAwake: false
  property bool stayAwakeStateLoaded: false
  property bool hasPendingStayAwakePersist: false
  property bool pendingStayAwakePersist: false
  property bool idleState: false
  property string lastEvent: "starting"
  property string lastEventAt: ""

  function nowIso() {
    return new Date().toISOString()
  }

  function logEvent(event, details) {
    var suffix = details === undefined || details === null || details === "" ? "" : ": " + String(details)
    root.lastEventAt = nowIso()
    root.lastEvent = event + suffix
    console.log("swayp idle " + root.lastEventAt + " " + root.lastEvent)
  }

  function persistStayAwake(value) {
    var command = value
      ? "mkdir -p \"$HOME/.local/state/swayp/indicators\" && touch \"$HOME/.local/state/swayp/indicators/stay-awake\""
      : "rm -f \"$HOME/.local/state/swayp/indicators/stay-awake\""

    if (stayAwakeStateWriter.running) {
      root.pendingStayAwakePersist = !!value
      root.hasPendingStayAwakePersist = true
      return
    }

    stayAwakeStateWriter.command = ["bash", "-lc", command]
    stayAwakeStateWriter.running = true
  }

  function refreshStayAwakeState() {
    if (!stayAwakeStateProbe.running) stayAwakeStateProbe.running = true
  }

  function applyStayAwake(value, persist, reason) {
    var enabled = !!value
    var changed = !root.stayAwakeStateLoaded || root.stayAwake !== enabled

    if (persist) persistStayAwake(enabled)

    root.stayAwake = enabled
    root.stayAwakeStateLoaded = true

    if (changed)
      logEvent("stay-awake", (enabled ? "enabled" : "disabled") + (reason ? " " + reason : ""))

    return enabled ? "disabled" : "enabled"
  }

  function setIdleEnabled(value) {
    return applyStayAwake(!value, true, "ipc")
  }

  function statusJson() {
    return JSON.stringify({
      owner: "swayidle",
      enabled: root.idleEnabled,
      stayAwake: root.stayAwake,
      stayAwakeStateLoaded: root.stayAwakeStateLoaded,
      stayAwakeStatePath: root.stayAwakeStatePath,
      idle: root.idleState,
      lock: root.lockTimeoutSeconds,
      dpms: root.dpmsTimeoutSeconds,
      lastEvent: root.lastEvent,
      lastEventAt: root.lastEventAt
    })
  }

  IdleMonitor {
    id: idleMonitor
    enabled: true
    timeout: 60
    respectInhibitors: true
    onIsIdleChanged: {
      root.idleState = isIdle
      root.logEvent("idle-monitor", isIdle ? "idle" : "active")
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: inhibitorWindow
      required property var modelData

      screen: modelData
      visible: root.stayAwake
      implicitWidth: 1
      implicitHeight: 1
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      focusable: false
      aboveWindows: false

      IdleInhibitor {
        window: inhibitorWindow
        enabled: root.stayAwake
      }
    }
  }

  Process {
    id: stayAwakeStateProbe
    command: [
      "bash",
      "-c",
      "mkdir -p \"$HOME/.local/state/swayp/indicators\"; if [[ -f $HOME/.local/state/swayp/indicators/stay-awake ]]; then echo yes; else echo no; fi"
    ]

    stdout: SplitParser {
      onRead: function(line) {
        root.applyStayAwake(String(line).trim() === "yes", false, "state-file")
      }
    }

    onExited: stayAwakeStateDirWatcher.reload()
  }

  Process {
    id: stayAwakeStateWriter

    onExited: {
      if (root.hasPendingStayAwakePersist) {
        var pending = root.pendingStayAwakePersist
        root.hasPendingStayAwakePersist = false
        root.persistStayAwake(pending)
        return
      }

      root.refreshStayAwakeState()
    }
  }

  FileView {
    id: stayAwakeStateDirWatcher
    path: root.stayAwakeStateDir
    watchChanges: true
    printErrors: false
    onFileChanged: root.refreshStayAwakeState()
  }

  Component.onCompleted: {
    logEvent("service-ready")
    refreshStayAwakeState()
  }

  IpcHandler {
    target: "idle"

    function status(): string {
      return root.statusJson()
    }

    function debug(): string {
      return root.statusJson()
    }

    function enable(): string {
      return root.setIdleEnabled(true)
    }

    function disable(): string {
      return root.setIdleEnabled(false)
    }

    function toggle(): string {
      // Toggle the persisted inhibitor state directly. Do not derive it from
      // the computed idleEnabled property, which depends on the async state probe.
      return root.applyStayAwake(!root.stayAwake, true, "ipc")
    }
  }
}
