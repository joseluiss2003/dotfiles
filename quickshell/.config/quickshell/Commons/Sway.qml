pragma Singleton
import QtQuick
import Quickshell
import Quickshell.I3

// Sway compositor facade.
// Keep compositor-specific access here so Omarchy UI components do not need
// to keep compositor-specific access out of Omarchy UI components.
QtObject {
  id: root

  readonly property var focusedMonitor: I3.focusedMonitor
  readonly property var focusedWorkspace: I3.focusedWorkspace
  readonly property var workspaces: I3.workspaces

  function dispatch(command) {
    return I3.dispatch(command)
  }
}
