import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import Quickshell.Io
import qs.core
import qs.ui

BarWidget {
  id: root
  moduleName: "swayp.workspaces"

  // Omarchy-style geometry: 1..5 are always visible. Sway workspaces
  // 6..10 appear when occupied, without changing the Sway backend.
  property var occupiedNumbers: []
  property int refreshSerial: 0

  function hasWindow(node) {
    if (!node) return false
    var type = String(node.type || "")
    if ((type === "con" || type === "floating_con") &&
        (node.app_id || node.window !== null && node.window !== undefined || node.pid !== null && node.pid !== undefined))
      return true
    var children = Array.isArray(node.nodes) ? node.nodes : []
    for (var i = 0; i < children.length; i++)
      if (root.hasWindow(children[i])) return true
    var floating = Array.isArray(node.floating_nodes) ? node.floating_nodes : []
    for (var j = 0; j < floating.length; j++)
      if (root.hasWindow(floating[j])) return true
    return false
  }

  function workspaceNumber(node) {
    if (!node) return -1
    var n = Number(node.num)
    if (isFinite(n)) return Math.round(n)
    n = Number(node.number)
    if (isFinite(n)) return Math.round(n)
    var name = String(node.name || "")
    var match = name.match(/^(\d+)/)
    return match ? Number(match[1]) : -1
  }

  function parseTree(raw) {
    var next = []
    try {
      var tree = JSON.parse(String(raw || "{}"))
      function visit(node) {
        if (!node) return
        if (String(node.type || "") === "workspace") {
          var num = root.workspaceNumber(node)
          if (num > 5 && num <= 10 && root.hasWindow(node) && next.indexOf(num) === -1)
            next.push(num)
        }
        var children = Array.isArray(node.nodes) ? node.nodes : []
        for (var i = 0; i < children.length; i++) visit(children[i])
        var floating = Array.isArray(node.floating_nodes) ? node.floating_nodes : []
        for (var j = 0; j < floating.length; j++) visit(floating[j])
      }
      visit(tree)
    } catch (e) {
      return
    }

    var focused = I3.focusedWorkspace
    if (focused && Number(focused.number) > 5 && Number(focused.number) <= 10 &&
        next.indexOf(Number(focused.number)) === -1)
      next.push(Number(focused.number))

    next.sort(function(a, b) { return a - b })
    root.occupiedNumbers = next
  }

  function refresh() {
    if (treeProcess.running) return
    root.refreshSerial++
    treeProcess.running = true
  }

  function workspaceByNumber(number) {
    var values = I3.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (Number(values[i].number) === Number(number)) return values[i]
    }
    return null
  }

  function workspaceNumbers() {
    var numbers = [1, 2, 3, 4, 5]
    for (var i = 0; i < root.occupiedNumbers.length; i++) {
      var number = Number(root.occupiedNumbers[i])
      if (number > 5 && number <= 10 && numbers.indexOf(number) === -1)
        numbers.push(number)
    }
    return numbers
  }

  function focusWorkspace(number) {
    var workspace = root.workspaceByNumber(number)
    if (workspace && typeof workspace.activate === "function") {
      workspace.activate()
      return
    }
    I3.dispatch("workspace number " + Number(number))
  }

  implicitWidth: grid.implicitWidth
  implicitHeight: grid.implicitHeight

  Process {
    id: treeProcess
    command: ["swaymsg", "-t", "get_tree", "-r"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseTree(text)
    }
  }

  Connections {
    target: I3
    function onRawEvent() { root.refresh() }
  }

  Timer {
    interval: 1500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  GridLayout {
    id: grid
    anchors.fill: parent
    columns: root.vertical ? 1 : root.workspaceNumbers().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceNumbers()

      WidgetButton {
        required property int modelData
        readonly property var workspace: root.workspaceByNumber(modelData)
        readonly property bool focused: !!workspace && !!workspace.focused
        readonly property bool occupied: root.occupiedNumbers.indexOf(modelData) !== -1 || focused
        readonly property bool urgent: !!workspace && !!workspace.urgent

        bar: root.bar
        text: focused ? "\uDB85\uDCFB" : (modelData === 10 ? "0" : String(modelData))
        active: focused
        activeColor: Color.accent
        opacity: focused ? 1.0 : (urgent ? 0.95 : (occupied ? 0.82 : 0.45))
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: root.focusWorkspace(modelData)
      }
    }
  }

  Component.onCompleted: root.refresh()
}
