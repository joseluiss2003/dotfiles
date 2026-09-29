import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.I3
import Quickshell.Wayland
import qs.core
import qs.ui
import "Model.js" as Model

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false

  property var cpuPrevious: null
  property real cpuUsage: 0
  property var memory: null
  property real loadAverage: 0
  property real uptimeSeconds: 0
  property var outputs: []
  property var swayState: ({ windows: 0, workspaces: 0, focused: "", focusedWorkspace: "" })
  property var gpu: null
  property string kernelVersion: "—"
  property string swayVersion: "—"
  property string quickshellVersion: "—"
  property string themeName: "—"
  property var plugins: []
  property bool refreshing: false

  readonly property var nightlightService: root.shell
    ? root.shell.firstPartyServiceFor("swayp.nightlight")
    : null
  readonly property var batteryService: root.shell
    ? root.shell.firstPartyServiceFor("swayp.battery")
    : null
  readonly property var mediaService: root.shell
    ? root.shell.firstPartyServiceFor("swayp.media")
    : null
  readonly property var idleService: root.shell
    ? root.shell.firstPartyServiceFor("swayp.idle")
    : null

  readonly property color panelBackground: Color.menu.background
  readonly property color panelForeground: Color.menu.text
  readonly property color panelBorder: Color.menu.border
  readonly property color muted: Color.textMuted
  readonly property color success: Color.success
  readonly property color warning: Color.warning
  readonly property color info: Color.info
  readonly property color accent: Color.accent

  function open(_payloadJson) {
    root.opened = true
    root.refresh()
    Qt.callLater(function() {
      if (root.opened) focusCatcher.forceActiveFocus()
    })
  }

  function close() {
    root.opened = false
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open("{}")
  }

  function refresh() {
    root.refreshing = true
    statsProc.running = false
    outputsProc.running = false
    treeProc.running = false
    gpuProc.running = false
    versionsProc.running = false

    statsProc.running = true
    outputsProc.running = true
    treeProc.running = true
    gpuProc.running = true
    versionsProc.running = true
    themeFile.reload()

    Qt.callLater(function() { root.refreshing = false })
  }

  function collectPlugins() {
    var registry = root.shell ? root.shell.pluginRegistry : null
    if (!registry || !registry.installedPlugins) {
      root.plugins = []
      return
    }

    var next = []
    var installed = registry.installedPlugins
    for (var id in installed) {
      if (!registry.isEnabled(id)) continue
      var manifest = installed[id]
      var label = manifest && manifest.name ? String(manifest.name) : String(id).replace(/^swayp\./, "")
      next.push({
        id: String(id),
        label: label,
        kind: Array.isArray(manifest && manifest.kinds) ? String(manifest.kinds[0]) : "plugin"
      })
    }

    next.sort(function(a, b) { return a.label.localeCompare(b.label) })
    root.plugins = next
  }

  function copyDiagnostics() {
    var lines = [
      "SwayP System Inspector",
      "SwayP plugins: " + root.plugins.length,
      "Kernel: " + root.kernelVersion,
      "Sway: " + root.swayVersion,
      "Quickshell: " + root.quickshellVersion,
      "Theme: " + root.themeName,
      "CPU: " + Math.round(root.cpuUsage) + "%",
      "Memory: " + (root.memory ? Math.round(root.memory.percent) + "%" : "—"),
      "Load: " + Model.formatLoad(root.loadAverage),
      "Uptime: " + Model.formatUptime(root.uptimeSeconds),
      "Windows: " + root.swayState.windows,
      "Workspaces: " + root.swayState.workspaces,
      "Focused: " + (root.swayState.focused || "—"),
      "Night Light: " + (root.nightlightService && root.nightlightService.enabled ? "on" : "off"),
      "Displays: " + root.outputs.length
    ]

    for (var i = 0; i < root.outputs.length; i++) {
      var output = root.outputs[i]
      lines.push(
        "Display " + output.name + ": " +
        output.width + "x" + output.height + " " +
        Model.formatRefresh(output.refresh) + " " +
        Model.formatScale(output.scale)
      )
    }

    Quickshell.execDetached([
      "bash", "-lc",
      "printf '%s\\n' " + lines.map(function(line) {
        return Util.shellQuote(line)
      }).join(" ") + " | wl-copy"
    ])
  }

  function metricColor(value, threshold, inverse) {
    var high = Number(value) >= Number(threshold)
    if (inverse) high = !high
    return high ? root.warning : root.success
  }

  Timer {
    id: refreshTimer
    interval: 1000
    repeat: true
    running: root.opened
    onTriggered: root.refresh()
  }

  FileView {
    id: themeFile
    path: Quickshell.env("HOME") + "/.config/swayp/current-theme"
    watchChanges: true
    printErrors: false
    onLoaded: {
      var value = String(themeFile.text() || "").trim()
      root.themeName = value.length > 0 ? value : "—"
    }
  }

  Process {
    id: statsProc
    command: ["bash", "-lc",
      "printf 'cpu\\t'; sed -n '1p' /proc/stat; " +
      "printf 'mem\\t'; cat /proc/meminfo; " +
      "printf 'load\\t'; cat /proc/loadavg; " +
      "printf 'uptime\\t'; cut -d' ' -f1 /proc/uptime"
    ]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").split("\n")
        var cpuRaw = ""
        var memRaw = ""
        var loadRaw = ""
        var uptimeRaw = ""

        var current = ""
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i]
          if (line.indexOf("cpu\t") === 0) {
            cpuRaw = line.slice(4)
            current = "cpu"
          } else if (line.indexOf("mem\t") === 0) {
            memRaw = line.slice(4)
            current = "mem"
          } else if (line.indexOf("load\t") === 0) {
            loadRaw = line.slice(5)
            current = "load"
          } else if (line.indexOf("uptime\t") === 0) {
            uptimeRaw = line.slice(7)
            current = "uptime"
          } else if (current === "cpu" && cpuRaw !== "") {
            cpuRaw += "\n" + line
          } else if (current === "mem") {
            memRaw += (memRaw ? "\n" : "") + line
          }
        }

        var cpuCurrent = Model.parseCpu(cpuRaw)
        root.cpuUsage = Model.cpuPercent(root.cpuPrevious, cpuCurrent)
        root.cpuPrevious = cpuCurrent
        root.memory = Model.parseMemory(memRaw)
        root.loadAverage = Model.parseLoad(loadRaw)
        root.uptimeSeconds = Number(uptimeRaw)
      }
    }
  }

  Process {
    id: outputsProc
    command: ["swaymsg", "-t", "get_outputs", "-r"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.outputs = Model.parseOutputs(text)
    }
  }

  Process {
    id: treeProc
    command: ["swaymsg", "-t", "get_tree", "-r"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.swayState = Model.parseTree(text)
    }
  }

  Process {
    id: gpuProc
    command: ["bash", "-lc",
      "command -v nvidia-smi >/dev/null 2>&1 && " +
      "nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw " +
      "--format=csv,noheader,nounits 2>/dev/null | sed -n '1p' || true"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.gpu = Model.parseGpu(text)
    }
  }

  Process {
    id: versionsProc
    command: ["bash", "-lc",
      "printf 'kernel\\t%s\\n' \"$(uname -r)\"; " +
      "printf 'sway\\t%s\\n' \"$(sway --version 2>/dev/null | sed -n '1p')\"; " +
      "printf 'quickshell\\t%s\\n' \"$(qs --version 2>/dev/null | sed -n '1p')\""
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split("\t")
          if (parts.length < 2) continue
          if (parts[0] === "kernel") root.kernelVersion = parts[1]
          else if (parts[0] === "sway") root.swayVersion = parts[1]
          else if (parts[0] === "quickshell") root.quickshellVersion = parts[1]
        }
      }
    }
  }

  Connections {
    target: root.shell && root.shell.pluginRegistry ? root.shell.pluginRegistry : null
    function onPluginsChanged() { root.collectPlugins() }
  }

  onShellChanged: root.collectPlugins()

  Component.onCompleted: root.collectPlugins()

  PanelWindow {
    id: panel

    screen: {
      var screens = Quickshell.screens || []
      var focused = I3.focusedMonitor
      if (focused) {
        for (var i = 0; i < screens.length; i++)
          if (String(screens[i].name || "") === String(focused.name || ""))
            return screens[i]
      }
      return screens.length > 0 ? screens[0] : null
    }

    visible: root.opened
    color: "transparent"

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    WlrLayershell.namespace: "swayp-inspector"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus:
      root.opened
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim
      opacity: root.opened ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Style.fullscreen.scrimDuration
          easing.type: Easing.OutCubic
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.opened
      onClicked: function(mouse) {
        if (mouse.x < card.x || mouse.x > card.x + card.width ||
            mouse.y < card.y || mouse.y > card.y + card.height)
          root.close()
      }
    }

    Item {
      id: focusCatcher
      anchors.fill: parent
      focus: root.opened
      Keys.priority: Keys.BeforeItem

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.close()
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_R) {
          root.refresh()
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier)) {
          root.copyDiagnostics()
          event.accepted = true
        }
      }

      Component.onCompleted: Qt.callLater(function() { forceActiveFocus() })
    }

    BorderSurface {
      id: card
      width: Math.min(Style.space(920), parent.width - Style.gapsOut * 2)
      height: Math.min(Style.space(720), parent.height - Style.gapsOut * 2)
      anchors.centerIn: parent
      color: root.panelBackground
      borderSpec: Border.surfaceSpec("menu", "border", root.panelBorder, Math.max(1, Style.space(2)))
      radius: Style.cornerRadius
      opacity: root.opened ? 1 : 0
      scale: root.opened ? 1 : 0.985

      Behavior on opacity {
        NumberAnimation {
          duration: Style.fullscreen.itemDuration
          easing.type: Easing.OutQuint
        }
      }

      Behavior on scale {
        NumberAnimation {
          duration: Style.fullscreen.settleDuration
          easing.type: Easing.OutQuint
        }
      }

      Column {
        anchors.fill: parent
        anchors.margins: Style.spacing.panelPadding
        spacing: Style.spacing.sectionGap

        Item {
          width: parent.width
          height: Math.max(Style.space(44), titleColumn.implicitHeight, headerActions.implicitHeight)

          Column {
            id: titleColumn
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.xxs

            Text {
              text: "SYSTEM INSPECTOR"
              color: root.panelForeground
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              text: root.themeName === "—"
                ? "SwayP live diagnostics"
                : root.themeName + " · SwayP live diagnostics"
              color: root.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }

          Row {
            id: headerActions
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.xs

            PanelActionButton {
              iconText: "󰑓"
              tooltipText: "Refresh"
              foreground: root.panelForeground
              hoverColor: root.accent
              bordered: true
              onClicked: root.refresh()
            }

            PanelActionButton {
              iconText: "󰆏"
              tooltipText: "Copy diagnostics"
              foreground: root.panelForeground
              hoverColor: root.accent
              bordered: true
              onClicked: root.copyDiagnostics()
            }

            PanelActionButton {
              iconText: "󰅖"
              tooltipText: "Close"
              foreground: root.panelForeground
              hoverColor: root.accent
              bordered: true
              onClicked: root.close()
            }
          }
        }

        Row {
          width: parent.width
          spacing: Style.spacing.sm
          height: Style.space(104)

          MetricBox {
            width: (parent.width - Style.spacing.sm * 2) / 3
            title: "CPU"
            value: Math.round(root.cpuUsage) + "%"
            detail: Model.formatLoad(root.loadAverage) + " load"
            accent: root.metricColor(root.cpuUsage, 80, false)
          }

          MetricBox {
            width: (parent.width - Style.spacing.sm * 2) / 3
            title: "MEMORY"
            value: root.memory ? Math.round(root.memory.percent) + "%" : "—"
            detail: root.memory
              ? Model.formatBytesFromKiB(root.memory.used) + " / " + Model.formatBytesFromKiB(root.memory.total)
              : "waiting"
            accent: root.memory ? root.metricColor(root.memory.percent, 85, false) : root.muted
          }

          MetricBox {
            width: (parent.width - Style.spacing.sm * 2) / 3
            title: "GPU"
            value: root.gpu ? Math.round(root.gpu.usage) + "%" : "—"
            detail: root.gpu
              ? Math.round(root.gpu.temperature) + "°C · " + Math.round(root.gpu.power) + "W"
              : "NVIDIA telemetry unavailable"
            accent: root.gpu ? root.metricColor(root.gpu.temperature, 75, false) : root.muted
          }
        }

        Row {
          width: parent.width
          spacing: Style.spacing.sm
          height: Style.space(104)

          MetricBox {
            width: (parent.width - Style.spacing.sm * 2) / 3
            title: "SWAY"
            value: root.swayState.windows
            detail: root.swayState.workspaces + " workspaces"
            accent: root.info
          }

          MetricBox {
            width: (parent.width - Style.spacing.sm * 2) / 3
            title: "UPTIME"
            value: Model.formatUptime(root.uptimeSeconds)
            detail: root.kernelVersion
            accent: root.accent
          }

          MetricBox {
            width: (parent.width - Style.spacing.sm * 2) / 3
            title: "NIGHT LIGHT"
            value: root.nightlightService && root.nightlightService.enabled ? "ON" : "OFF"
            detail: root.nightlightService
              ? (root.nightlightService.enabled ? "4000K" : "6500K")
              : "service unavailable"
            accent: root.nightlightService && root.nightlightService.enabled ? root.warning : root.muted
          }
        }

        Row {
          width: parent.width
          spacing: Style.spacing.xxl
          height: Style.space(154)

          Column {
            width: (parent.width - Style.spacing.xxl) * 0.52
            spacing: Style.spacing.sm

            SectionLabel { text: "DISPLAYS" }

            Column {
              width: parent.width
              spacing: Style.spacing.xxs

              Repeater {
                model: root.outputs

                delegate: BorderSurface {
                  required property var modelData
                  width: parent.width
                  height: Style.space(34)
                  color: modelData.focused ? Color.active : "transparent"
                  borderSpec: Border.none()
                  radius: Style.cornerRadius

                  Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Style.spacing.sm
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                    color: root.panelForeground
                    font.family: Style.font.family
                    font.pixelSize: Style.font.bodySmall
                    font.bold: true
                  }

                  Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Style.spacing.sm
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.width + "×" + modelData.height +
                      "  " + Model.formatRefresh(modelData.refresh) +
                      "  " + Model.formatScale(modelData.scale)
                    color: root.muted
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                  }
                }
              }
            }
          }

          Column {
            width: (parent.width - Style.spacing.xxl) * 0.48
            spacing: Style.spacing.sm

            SectionLabel { text: "RUNTIME" }

            Column {
              width: parent.width
              spacing: Style.spacing.xxs

              RuntimeLine { label: "Sway"; value: root.swayVersion }
              RuntimeLine { label: "Quickshell"; value: root.quickshellVersion }
              RuntimeLine { label: "Focused"; value: root.swayState.focused || "—" }
              RuntimeLine { label: "Workspace"; value: root.swayState.focusedWorkspace || "—" }
            }
          }
        }

        Item {
          width: parent.width
          height: parent.height - y

          Column {
            anchors.fill: parent
            spacing: Style.spacing.sm

            SectionLabel { text: "PLUGINS" }

            Flickable {
              width: parent.width
              height: parent.height - y
              clip: true
              contentWidth: width
              contentHeight: pluginGrid.implicitHeight

              Flow {
                id: pluginGrid
                width: parent.width
                spacing: Style.spacing.xs

                Repeater {
                  model: root.plugins

                  delegate: BorderSurface {
                    required property var modelData
                    implicitWidth: pluginLabel.implicitWidth + Style.spacing.xxl * 2
                    implicitHeight: Style.space(28)
                    color: Color.surfaceAlt
                    borderSpec: Border.surfaceSpec("control", "border", Color.controls.border, 1)
                    radius: Style.cornerRadius

                    Text {
                      id: pluginLabel
                      anchors.centerIn: parent
                      text: modelData.label
                      color: root.panelForeground
                      font.family: Style.font.family
                      font.pixelSize: Style.font.caption
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  component SectionLabel: Text {
    color: root.panelForeground
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.bold: true
  }

  component RuntimeLine: Row {
    id: runtimeLine
    required property string label
    required property string value
    width: parent.width
    height: Style.space(25)
    spacing: Style.spacing.md

    Text {
      width: Style.space(82)
      text: runtimeLine.label
      color: root.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    Text {
      width: parent.width - Style.space(82) - parent.spacing
      text: runtimeLine.value
      color: root.panelForeground
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }
  }

  component MetricBox: BorderSurface {
    required property string title
    required property string value
    required property string detail
    required property color accent

    color: Color.surfaceAlt
    borderSpec: Border.surfaceSpec("control", "border", Color.controls.border, 1)
    radius: Style.cornerRadius

    Column {
      anchors.left: parent.left
      anchors.leftMargin: Style.spacing.lg
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.spacing.xxs

      Text {
        text: parent.parent.title
        color: root.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Text {
        text: parent.parent.value
        color: parent.parent.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.title
        font.bold: true
      }

      Text {
        text: parent.parent.detail
        color: root.panelForeground
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }
  }
}
