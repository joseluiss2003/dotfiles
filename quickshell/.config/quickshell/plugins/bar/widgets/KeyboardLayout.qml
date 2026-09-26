import QtQuick
import Quickshell
import Quickshell.Io
import qs.ui
import qs.core

BarWidget {
  id: root
  moduleName: "omarchy.keyboard-layout"

  property var layoutNames: []
  property int layoutIndex: 0
  property string activeLayout: ""

  readonly property bool multipleLayouts: layoutNames.length > 1
  readonly property string layoutLabel: {
    if (activeLayout.length === 0) return "—"
    var paren = activeLayout.indexOf(" (")
    return paren > 0 ? activeLayout.substring(0, paren) : activeLayout
  }

  visible: multipleLayouts
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!queryProc.running) queryProc.running = true
  }

  function cycleLayout() {
    if (!root.multipleLayouts) return
    root.bar.run("swaymsg input type:keyboard xkb_switch_layout next")
    refreshTimer.restart()
  }

  Process {
    id: queryProc
    command: ["swaymsg", "-t", "get_inputs", "-r"]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parsed
        try {
          parsed = JSON.parse(text || "[]")
        } catch (e) {
          return
        }

        var keyboards = []
        for (var i = 0; i < parsed.length; i++) {
          var input = parsed[i]
          if (input && input.type === "keyboard") keyboards.push(input)
        }
        if (keyboards.length === 0) return

        var keyboard = keyboards[0]
        var names = keyboard.xkb_layout_names || []
        var active = keyboard.xkb_active_layout_name || ""

        root.layoutNames = names
        root.activeLayout = active
        root.layoutIndex = Number(keyboard.xkb_active_layout_index || 0)
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 700
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    interval: 2000
    running: root.visible || root.layoutNames.length === 0
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: root.refresh()

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.layoutLabel
    tooltipText: root.activeLayout
    onPressed: root.cycleLayout()
  }
}
