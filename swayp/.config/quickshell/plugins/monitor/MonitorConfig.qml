import QtQuick
import QtQuick.Controls
import qs.ui
import qs.core

Column {
  id: root

  required property var display
  required property var bar
  property color foreground: Color.foreground
  property var refreshState: null
  property int resolutionIndex: 0
  property int refreshIndex: 0

  readonly property var resolutions: ModelDataHelper.uniqueResolutions(display ? display.modes : [])
  readonly property var refreshRates: ModelDataHelper.refreshRatesFor(display ? display.modes : [], currentResolution())
  readonly property var transforms: ["normal", "90", "180", "270", "flipped", "flipped-90", "flipped-180", "flipped-270"]
  readonly property var scales: [1, 1.25, 1.5, 1.75, 2]

  spacing: Style.spacing.xs
  width: parent ? parent.width : 0

  function currentResolution() {
    if (!resolutions.length) return { width: display?.currentMode?.width || 0, height: display?.currentMode?.height || 0 }
    return resolutions[Math.max(0, Math.min(resolutionIndex, resolutions.length - 1))]
  }

  function syncSelection() {
    if (!display) return
    var current = display.currentMode || {}
    var best = 0
    for (var i = 0; i < resolutions.length; i++) {
      if (resolutions[i].width === current.width && resolutions[i].height === current.height) {
        best = i
        break
      }
    }
    resolutionIndex = best
    if (xField) xField.text = String(display.x || 0)
    if (yField) yField.text = String(display.y || 0)

    var rates = ModelDataHelper.refreshRatesFor(display.modes || [], currentResolution())
    var rateBest = 0
    for (var j = 0; j < rates.length; j++) {
      if (Math.abs(Number(rates[j]) - Number(current.refresh) / 1000) < 0.01) {
        rateBest = j
        break
      }
    }
    refreshIndex = rateBest
  }

  function run(action, args) {
    var output = String(display?.name || "")
    if (!output) return
    var command = ["swayp-monitor-control", output, action].concat(args || [])
    controlProc.command = command
    controlProc.running = true
  }

  function setResolution(delta) {
    if (!resolutions.length) return
    resolutionIndex = (resolutionIndex + delta + resolutions.length) % resolutions.length
    refreshIndex = 0
  }

  function setRefresh(delta) {
    if (!refreshRates.length) return
    refreshIndex = (refreshIndex + delta + refreshRates.length) % refreshRates.length
  }

  function applyMode() {
    var res = currentResolution()
    if (!res.width || !res.height || !refreshRates.length) return
    run("mode", [String(res.width), String(res.height), String(refreshRates[refreshIndex])])
  }

  function applyPosition() {
    run("position", [String(xField.text), String(yField.text)])
  }

  function transformIndex() {
    var idx = transforms.indexOf(String(display?.transform || "normal"))
    return idx >= 0 ? idx : 0
  }

  function cycleTransform(delta) {
    var idx = (transformIndex() + delta + transforms.length) % transforms.length
    run("transform", [transforms[idx]])
  }

  function cycleScale(delta) {
    var current = Number(display?.scale || 1)
    var idx = 0
    var best = 1e9
    for (var i = 0; i < scales.length; i++) {
      var d = Math.abs(scales[i] - current)
      if (d < best) { best = d; idx = i }
    }
    idx = (idx + delta + scales.length) % scales.length
    run("scale", [String(scales[idx])])
  }

  onDisplayChanged: syncSelection()
  onResolutionsChanged: syncSelection()
  Component.onCompleted: syncSelection()

  QtObject {
    id: ModelDataHelper
    function uniqueResolutions(modes) {
      var out = []
      var seen = {}
      for (var i = 0; i < (modes || []).length; i++) {
        var m = modes[i]
        var key = String(m.width) + "x" + String(m.height)
        if (!seen[key]) {
          seen[key] = true
          out.push({ width: Number(m.width), height: Number(m.height) })
        }
      }
      return out
    }
    function refreshRatesFor(modes, resolution) {
      var out = []
      var seen = {}
      for (var i = 0; i < (modes || []).length; i++) {
        var m = modes[i]
        if (!resolution || Number(m.width) !== Number(resolution.width) || Number(m.height) !== Number(resolution.height)) continue
        var hz = Number(m.refresh) / 1000
        var key = hz.toFixed(3)
        if (!seen[key]) {
          seen[key] = true
          out.push(Number(key))
        }
      }
      return out
    }
  }

  Process {
    id: controlProc
    stdout: StdioCollector { waitForEnd: true }
    onRunningChanged: if (!running && root.refreshState) root.refreshState()
  }

  Item {
    width: parent.width
    height: Style.space(28)

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "MODE"
      color: root.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.spacing.xs

      Button { text: "‹"; bordered: true; verticalPadding: 2; horizontalPadding: 7; onClicked: root.setResolution(-1) }
      Button {
        text: root.resolutions.length ? (root.currentResolution().width + "×" + root.currentResolution().height) : "N/A"
        bordered: true
        verticalPadding: 2
        horizontalPadding: 8
        onClicked: root.applyMode()
      }
      Button { text: "›"; bordered: true; verticalPadding: 2; horizontalPadding: 7; onClicked: root.setResolution(1) }

      Button { text: "‹"; bordered: true; verticalPadding: 2; horizontalPadding: 7; onClicked: { root.setRefresh(-1); root.applyMode() } }
      Button { text: root.refreshRates.length ? (Number(root.refreshRates[root.refreshIndex]).toFixed(3) + " Hz") : "N/A"; bordered: true; verticalPadding: 2; horizontalPadding: 8; onClicked: root.applyMode() }
      Button { text: "›"; bordered: true; verticalPadding: 2; horizontalPadding: 7; onClicked: { root.setRefresh(1); root.applyMode() } }
    }
  }

  Item {
    width: parent.width
    height: Style.space(28)

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "POSITION"
      color: root.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.spacing.xs

      TextField {
        id: xField
        width: Style.space(74)
        height: Style.space(28)
        text: String(display?.x || 0)
        validator: IntValidator { bottom: -32768; top: 32767 }
        color: root.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        selectByMouse: true
      }
      TextField {
        id: yField
        width: Style.space(74)
        height: Style.space(28)
        text: String(display?.y || 0)
        validator: IntValidator { bottom: -32768; top: 32767 }
        color: root.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        selectByMouse: true
      }
      Button { text: "APPLY"; bordered: true; verticalPadding: 2; onClicked: root.applyPosition() }
    }
  }

  Item {
    width: parent.width
    height: Style.space(28)

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "TRANSFORM"
      color: root.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.spacing.xs
      Button { text: "‹"; bordered: true; verticalPadding: 2; horizontalPadding: 7; onClicked: root.cycleTransform(-1) }
      Button { text: String(root.display?.transform || "normal").toUpperCase(); bordered: true; verticalPadding: 2; horizontalPadding: 8; onClicked: root.cycleTransform(1) }
      Button { text: "›"; bordered: true; verticalPadding: 2; horizontalPadding: 7; onClicked: root.cycleTransform(1) }
    }
  }

  Item {
    width: parent.width
    height: Style.space(28)

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "SCALE"
      color: root.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    Button {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: Number(root.display?.scale || 1).toFixed(2) + "×"
      bordered: true
      verticalPadding: 2
      horizontalPadding: 10
      onClicked: root.cycleScale(1)
    }
  }

  Item {
    width: parent.width
    height: Style.space(28)

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "VRR"
      color: root.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    Button {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      visible: !!root.display?.adaptiveSyncSupported
      text: String(root.display?.adaptiveSync || "unsupported").toUpperCase()
      bordered: true
      verticalPadding: 2
      horizontalPadding: 10
      onClicked: root.run("adaptive-sync", [String(root.display.adaptiveSync === "enabled" ? "off" : "on")])
    }
  }

  Item {
    width: parent.width
    height: Style.space(30)

    Button {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: root.display?.power ? "POWER OFF" : "POWER ON"
      bordered: true
      verticalPadding: 2
      horizontalPadding: 10
      onClicked: root.run("power", [root.display?.power ? "off" : "on"])
    }
  }
}
