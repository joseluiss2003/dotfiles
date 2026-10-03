import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.core
import qs.ui

Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool open: false
  property int selectedIndex: 0
  property var windows: []
  property var mru: []
  property int cycleSerial: 0

  readonly property int cardWidth: Style.space(620)
  readonly property int cardHeight: Style.space(166)
  readonly property int itemWidth: Style.space(112)
  readonly property int itemHeight: Style.space(108)

  function windowTitle(toplevel) {
    var title = String(toplevel ? toplevel.title || "" : "").trim()
    var app = String(toplevel ? toplevel.appId || "" : "").trim()
    return title || app || "Window"
  }

  function windowApp(toplevel) {
    var app = String(toplevel ? toplevel.appId || "" : "").trim()
    if (!app) return "Application"
    var value = app.split(".")
    var last = value.length ? value[value.length - 1] : app
    return last.charAt(0).toUpperCase() + last.slice(1)
  }

  function validWindows() {
    var values = ToplevelManager.toplevels.values || []
    var out = []
    for (var i = 0; i < values.length; i++) {
      var w = values[i]
      if (!w || !w.appId && !w.title) continue
      if (w.minimized) continue
      if (out.indexOf(w) === -1) out.push(w)
    }
    return out
  }

  function syncMru() {
    var available = validWindows()
    var next = []

    // Keep the existing MRU order for windows that still exist.
    for (var i = 0; i < mru.length; i++) {
      if (available.indexOf(mru[i]) !== -1 && next.indexOf(mru[i]) === -1)
        next.push(mru[i])
    }

    // Newly discovered windows are appended behind existing MRU entries.
    for (var j = 0; j < available.length; j++) {
      if (next.indexOf(available[j]) === -1) next.push(available[j])
    }

    var active = ToplevelManager.activeToplevel
    if (active && next.indexOf(active) !== -1) {
      next.splice(next.indexOf(active), 1)
      next.unshift(active)
    }

    mru = next
  }

  function beginCycle(direction) {
    syncMru()
    if (mru.length < 2) return

    windows = mru.slice()
    open = true
    selectedIndex = direction > 0 ? 1 : windows.length - 1
    cycleSerial++
  }

  function cycle(direction) {
    if (!open) {
      beginCycle(direction)
      return
    }
    if (windows.length < 2) return
    selectedIndex = (selectedIndex + direction + windows.length) % windows.length
    cycleSerial++
  }

  function commit() {
    if (!open) return
    var selected = windows[selectedIndex]
    open = false
    if (selected && typeof selected.activate === "function")
      selected.activate()
    syncMru()
  }

  function cancel() {
    open = false
  }

  function iconSource(toplevel) {
    var app = String(toplevel ? toplevel.appId || "" : "")
    if (app.length > 0) {
      var themed = Quickshell.iconPath(app, true)
      if (themed.length > 0) return themed
    }
    return Quickshell.iconPath("application-x-executable", true)
  }

  function toggle() {
    if (open) cancel()
    else beginCycle(1)
  }

  IpcHandler {
    target: "swayp.alt-switch"

    function next(): string {
      root.cycle(1)
      return "ok"
    }

    function previous(): string {
      root.cycle(-1)
      return "ok"
    }

    function commit(): string {
      root.commit()
      return "ok"
    }

    function cancel(): string {
      root.cancel()
      return "ok"
    }

    function toggle(): string {
      root.toggle()
      return "ok"
    }
  }

  Connections {
    target: ToplevelManager

    function onActiveToplevelChanged() {
      if (!root.open) root.syncMru()
    }
  }

  Connections {
    target: ToplevelManager.toplevels

    function onValuesChanged() {
      if (!root.open) root.syncMru()
    }
  }

  Component.onCompleted: root.syncMru()

  Item {
    id: keyCatcher
    anchors.fill: parent
    focus: root.open
    Keys.priority: Keys.BeforeItem

    Keys.onPressed: function(event) {
      if (!root.open) return

      if (event.key === Qt.Key_Tab) {
        root.cycle((event.modifiers & Qt.ShiftModifier) ? -1 : 1)
        event.accepted = true
        return
      }

      if (event.key === Qt.Key_Backtab) {
        root.cycle(-1)
        event.accepted = true
        return
      }

      if (event.key === Qt.Key_Escape) {
        root.cancel()
        event.accepted = true
        return
      }
    }

    Keys.onReleased: function(event) {
      if (root.open && event.key === Qt.Key_Alt) {
        root.commit()
        event.accepted = true
      }
    }
  }

  Variants {
    model: root.open ? Quickshell.screens : []

    delegate: Component {
      PanelWindow {
        property var modelData

        screen: modelData
        visible: root.open
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "swayp-alt-switch"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }

        Item {
          anchors.fill: parent

          BorderSurface {
            id: card

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: root.cardWidth
            height: root.cardHeight

            color: Util.alpha(Color.background, 0.96)
            borderSpec: Border.surfaceSpec(
              "alt-switch",
              "border",
              Util.alpha(Color.accent, 0.72),
              1
            )
            padding: Style.space(10)
            radius: 0

            ColumnLayout {
              anchors.fill: parent
              spacing: Style.space(6)

              RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Style.space(20)

                Text {
                  text: "> alt-tab"
                  color: Color.accent
                  font.family: Style.font.menuFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                  text: root.windows.length > 1
                    ? (String(root.selectedIndex + 1) + "/" + String(root.windows.length))
                    : ""
                  color: Color.textMuted
                  font.family: Style.font.menuFamily
                  font.pixelSize: Style.font.small
                }
              }

              ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: ListView.Horizontal
                spacing: Style.space(6)
                clip: true
                interactive: false
                model: root.windows.length ? root.windows : []

                delegate: Item {
                  property var modelData
                  property int index: 0

                  width: root.itemWidth
                  height: root.itemHeight

                  readonly property bool selected: Number(index) === root.selectedIndex

                  BorderSurface {
                    anchors.fill: parent
                    color: selected
                      ? Util.alpha(Color.selection, 0.92)
                      : Util.alpha(Color.surface, 0.55)
                    borderSpec: Border.surfaceSpec(
                      "alt-switch-item",
                      "border",
                      selected
                        ? Util.alpha(Color.accent, 0.95)
                        : Util.alpha(Color.outline, 0.38),
                      selected ? 1 : 1
                    )
                    padding: Style.space(6)
                    radius: 0

                    ColumnLayout {
                      anchors.fill: parent
                      spacing: Style.space(6)

                      Image {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Style.space(34)
                        Layout.preferredHeight: Style.space(34)
                        source: root.iconSource(modelData)
                        sourceSize.width: Style.space(34)
                        sourceSize.height: Style.space(34)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                      }

                      Text {
                        Layout.fillWidth: true
                        text: root.windowApp(modelData)
                        color: selected ? Color.foreground : Color.text
                        font.family: Style.font.menuFamily
                        font.pixelSize: Style.font.small
                        font.bold: selected
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                      }

                      Text {
                        Layout.fillWidth: true
                        text: root.windowTitle(modelData)
                        color: selected ? Color.foreground : Color.textMuted
                        font.family: Style.font.menuFamily
                        font.pixelSize: Style.font.tiny
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                      }
                    }
                  }

                  Behavior on opacity {
                    NumberAnimation { duration: 100 }
                  }

                  opacity: selected ? 1.0 : 0.78
                }

                onModelChanged: {
                  if (root.windows.length > 0)
                    currentIndex = Math.max(0, Math.min(root.selectedIndex, root.windows.length - 1))
                }

                Connections {
                  target: root
                  function onSelectedIndexChanged() {
                    if (root.windows.length > 0)
                      list.currentIndex = Math.max(0, Math.min(root.selectedIndex, root.windows.length - 1))
                  }
                }

                Component.onCompleted: {
                  if (root.windows.length > 0)
                    currentIndex = root.selectedIndex
                }
              }
            }
          }
        }
      }
    }
  }
}
