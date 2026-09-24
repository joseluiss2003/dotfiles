import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.system-monitor"

  property real cpuUsage: 0
  property real memoryUsage: 0
  property real memoryUsedGiB: 0
  property real memoryTotalGiB: 0
  property real gpuUsage: 0
  property real gpuMemoryUsage: 0
  property real gpuTemp: 0
  property real rxRate: 0
  property real txRate: 0
  property string primaryInterface: ""
  property string gpuName: ""
  property var previousCpu: null
  property var previousNet: ({})
  property bool opened: false

  function open() { root.opened = true; root.refresh() }
  function close() { root.opened = false }
  function toggle() { root.opened = !root.opened; if (root.opened) root.refresh() }

  function parseCpu(raw) {
    var line = String(raw || "").split("\n")[0].trim().split(/\s+/)
    if (line.length < 5 || line[0] !== "cpu") return
    var values = []
    for (var i = 1; i < line.length; i++) values.push(Number(line[i]) || 0)
    var idle = (values[3] || 0) + (values[4] || 0)
    var total = 0
    for (var j = 0; j < values.length; j++) total += values[j]
    if (root.previousCpu) {
      var deltaTotal = total - root.previousCpu.total
      var deltaIdle = idle - root.previousCpu.idle
      if (deltaTotal > 0) root.cpuUsage = Math.max(0, Math.min(100, 100 * (1 - deltaIdle / deltaTotal)))
    }
    root.previousCpu = { total: total, idle: idle }
  }

  function parseMemory(raw) {
    var total = 0
    var available = 0
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].trim().split(/\s+/)
      if (parts[0] === "MemTotal:") total = Number(parts[1]) * 1024
      else if (parts[0] === "MemAvailable:") available = Number(parts[1]) * 1024
    }
    if (total <= 0) return
    var used = Math.max(0, total - available)
    root.memoryTotalGiB = total / 1073741824
    root.memoryUsedGiB = used / 1073741824
    root.memoryUsage = Math.max(0, Math.min(100, 100 * used / total))
  }

  function parseGpu(raw) {
    var lines = String(raw || "").trim().split("\n")
    if (!lines.length || !String(lines[0]).trim()) return
    var parts = lines[0].split(",")
    if (parts.length < 5) return
    root.gpuName = String(parts[0]).trim()
    root.gpuUsage = Number(String(parts[1]).trim()) || 0
    root.gpuTemp = Number(String(parts[2]).trim()) || 0
    var memUsed = Number(String(parts[3]).trim()) || 0
    var memTotal = Number(String(parts[4] || "").trim()) || 0
    root.gpuMemoryUsage = memTotal > 0 ? (100 * memUsed / memTotal) : 0
  }

  function parseNetwork(raw) {
    var current = ({})
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i]
      if (line.indexOf(":") < 0) continue
      var p = line.trim().split(/\s+/)
      var iface = p[0]
      if (iface === "lo" || p.length < 9) continue
      var rx = Number(p[1]) || 0
      var tx = Number(p[9]) || 0
      current[iface] = { rx: rx, tx: tx }
    }

    var rx = 0
    var tx = 0
    for (var name in current) {
      if (root.previousNet[name]) {
        rx += Math.max(0, current[name].rx - root.previousNet[name].rx)
        tx += Math.max(0, current[name].tx - root.previousNet[name].tx)
      }
    }
    root.previousNet = current
    root.rxRate = rx / 2
    root.txRate = tx / 2
  }

  function formatRate(bytes) {
    if (bytes < 1024) return Math.round(bytes) + " B/s"
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB/s"
    return (bytes / 1048576).toFixed(1) + " MB/s"
  }

  function refresh() {
    cpuProc.running = true
    memoryProc.running = true
    gpuProc.running = true
    networkProc.running = true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰍛"
    opticalSize: Style.bar.iconCanvas
    fontSize: Style.bar.iconFont
    tooltipText: "System monitor"
    onPressed: root.toggle()
  }

  Process {
    id: cpuProc
    command: ["cat", "/proc/stat"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.parseCpu(text) }
  }

  Process {
    id: memoryProc
    command: ["cat", "/proc/meminfo"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.parseMemory(text) }
  }

  Process {
    id: gpuProc
    command: ["/usr/bin/nvidia-smi", "--query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.parseGpu(text) }
  }

  Process {
    id: networkProc
    command: ["cat", "/proc/net/dev"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.parseNetwork(text) }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.opened
    contentWidth: popup.fittedContentWidth(Style.space(390))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      Row {
        width: parent.width
        spacing: Style.space(10)

        Text {
          text: "󰍛"
          color: Color.accent
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.display
          anchors.verticalCenter: parent.verticalCenter
        }

        Column {
          spacing: Style.space(2)
          anchors.verticalCenter: parent.verticalCenter

          Text {
            text: "System Monitor"
            color: Color.text
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.heading
            font.bold: true
          }

          Text {
            text: "SWAY · LIVE"
            color: Color.textMuted
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
          }
        }
      }

      PanelSeparator { foreground: Color.outline }

      component Metric: BorderSurface {
        required property string iconText
        required property string labelText
        required property string valueText
        required property real percentValue

        width: parent ? parent.width : 0
        implicitHeight: Style.space(58)
        color: Util.alpha(Color.surfaceAlt, 0.35)
        borderSpec: Border.flat(Util.alpha(Color.outline, 0.45), 1)

        Column {
          anchors.fill: parent
          anchors.margins: Style.space(9)
          spacing: Style.space(5)

          Row {
            width: parent.width
            spacing: Style.space(8)

            Text { text: iconText; color: Color.accent; font.family: root.bar.fontFamily; font.pixelSize: Style.font.icon }
            Text { text: labelText; color: Color.textMuted; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
            Item { width: Math.max(1, parent.width - Style.space(170)) }
            Text { text: valueText; color: Color.text; font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
          }

          Rectangle {
            width: parent.width
            height: Style.space(4)
            radius: height / 2
            color: Util.alpha(Color.outline, 0.3)

            Rectangle {
              width: parent.width * Math.max(0, Math.min(1, percentValue / 100))
              height: parent.height
              radius: height / 2
              color: Color.accent
            }
          }
        }
      }

      Metric {
        iconText: "󰍛"
        labelText: "CPU"
        valueText: Math.round(root.cpuUsage) + "%"
        percentValue: root.cpuUsage
      }

      Metric {
        iconText: "󰘚"
        labelText: "MEMORY"
        valueText: root.memoryUsedGiB.toFixed(1) + " / " + root.memoryTotalGiB.toFixed(1) + " GiB"
        percentValue: root.memoryUsage
      }

      Metric {
        iconText: "󰢮"
        labelText: "GPU"
        valueText: Math.round(root.gpuUsage) + "% · " + Math.round(root.gpuTemp) + "°C"
        percentValue: root.gpuUsage
      }

      Metric {
        iconText: "󰢮"
        labelText: "VRAM"
        valueText: Math.round(root.gpuMemoryUsage) + "%"
        percentValue: root.gpuMemoryUsage
      }

      BorderSurface {
        width: parent.width
        implicitHeight: Style.space(62)
        color: Util.alpha(Color.surfaceAlt, 0.35)
        borderSpec: Border.flat(Util.alpha(Color.outline, 0.45), 1)

        Row {
          anchors.fill: parent
          anchors.margins: Style.space(12)
          spacing: Style.space(10)

          Text { text: "󰈀"; color: Color.accent; font.family: root.bar.fontFamily; font.pixelSize: Style.font.icon; anchors.verticalCenter: parent.verticalCenter }

          Column {
            width: parent.width - Style.space(38)
            spacing: Style.space(2)
            anchors.verticalCenter: parent.verticalCenter

            Text {
              width: parent.width
              text: "NETWORK"
              color: Color.textMuted
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Text {
              width: parent.width
              text: "↓ " + root.formatRate(root.rxRate) + "   ↑ " + root.formatRate(root.txRate)
              color: Color.text
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.body
            }
          }
        }
      }

      Text {
        width: parent.width
        text: root.gpuName || "NVIDIA GPU unavailable"
        color: Color.textMuted
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }
  }

  Component.onCompleted: root.refresh()
}
