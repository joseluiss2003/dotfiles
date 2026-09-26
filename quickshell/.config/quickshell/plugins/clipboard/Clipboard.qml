import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "ClipboardHistory.js" as ClipboardHistory

Item {
  id: root

  property string omarchyPath: {
    var configured = Quickshell.env("OMARCHY_PATH")
    var home = Quickshell.env("HOME")
    return configured && configured.trim() !== "" ? configured : home + "/.local/share/omarchy-quattro-sway/source"
  }
  property bool opened: false
  // Injected by the bar-widget host so PopupCard can anchor to the actual bar button.
  property Item anchorItem: null
  property QtObject bar: null
  property int selectedIndex: 0
  property bool cursorActive: false
  property bool clearConfirmOpen: false
  property var history: []

  property string historyPath: Quickshell.env("HOME") + "/.local/state/omarchy/clipboard-history.json"
  property string captureScript: Quickshell.env("HOME") + "/.config/quickshell/plugins/clipboard/capture.sh"
  // Shares the [menu] surface tokens — themes that style the menu also
  // style the clipboard. Selected-row colors composed in the
  // singleton so consumers drop them straight into Rectangle bindings.
  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.text
  readonly property int cornerRadius: 0
  property string fontFamily: Style.font.menuFamily
  property int contentMargin: Style.space(12)
  property int headerHeight: Style.space(48)
  property int contentSpacing: 0
  property int cardWidth: Style.space(440)
  property int cardHeight: Style.space(390)
  property int rowHeight: Style.space(46)
  property int historyLimit: 500

  function open(payloadJson) {
    root.opened = true
    root.selectedIndex = 0
    root.cursorActive = true
    root.disarmPointer()
    root.rebuildDisplay()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.cancelClearHistory()
    root.opened = false
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open("{}")
  }

  function normalizeEntry(value) {
    return ClipboardHistory.normalizeEntry(value)
  }

  function entryKey(entry) {
    return ClipboardHistory.entryKey(entry)
  }

  function loadHistory(raw) {
    root.history = ClipboardHistory.parseHistory(raw)
    if (root.opened) root.rebuildDisplay()
  }

  function saveHistory() {
    historyFile.setText(JSON.stringify(root.history.slice(0, root.historyLimit), null, 2) + "\n")
  }

  function addClipboardEntry(entry) {
    var normalized = ClipboardHistory.normalizeEntry(entry)
    if (!normalized) return

    root.history = ClipboardHistory.addEntry(root.history, normalized, root.historyLimit)
    root.saveHistory()
    if (root.opened) root.rebuildDisplay()
  }

  function addClipboardJson(line) {
    root.addClipboardEntry(ClipboardHistory.parseEntryJson(line))
  }

  function requestClearHistory() {
    if (root.history.length === 0) return
    clearConfirm.selectedIndex = 1
    root.clearConfirmOpen = true
  }

  function cancelClearHistory() {
    root.clearConfirmOpen = false
    root.disarmPointer()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function confirmClearHistory() {
    root.history = ClipboardHistory.clearHistory()
    root.saveHistory()
    root.selectedIndex = 0
    root.cursorActive = false
    root.disarmPointer()
    root.clearConfirmOpen = false
    root.rebuildDisplay()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function removeDisplayIndex(index) {
    if (index < 0 || index >= displayModel.count) return

    var row = displayModel.get(index)
    root.history = ClipboardHistory.removeEntryAt(root.history, row.historyIndex)
    root.saveHistory()

    if (displayModel.count <= 1) {
      root.selectedIndex = 0
      root.cursorActive = false
    } else if (root.selectedIndex >= displayModel.count - 1) {
      root.selectedIndex = displayModel.count - 2
    }

    root.disarmPointer()
    root.rebuildDisplay()
  }

  function rebuildDisplay() {
    var rows = ClipboardHistory.displayRows(root.history, "", 50)

    displayModel.clear()
    for (var i = 0; i < rows.length; i++) {
      var row = rows[i]
      displayModel.append({
        entryType: row.entryType,
        fullText: row.fullText,
        previewText: row.previewText,
        previewImage: row.previewImage ? Util.fileUrl(row.previewImage) : "",
        path: row.path,
        mime: row.mime,
        historyIndex: row.index
      })
    }

    if (displayModel.count === 0) selectedIndex = 0
    else if (selectedIndex >= displayModel.count) selectedIndex = displayModel.count - 1
    else if (selectedIndex < 0) selectedIndex = 0

    Qt.callLater(function() {
      if (displayModel.count > 0) resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    })
  }

  function select(delta) {
    if (displayModel.count === 0) return
    root.disarmPointer()
    if (!cursorActive) {
      cursorActive = true
      selectedIndex = delta < 0 ? displayModel.count - 1 : 0
    } else {
      selectedIndex = (selectedIndex + delta + displayModel.count) % displayModel.count
    }
    resultList.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  function selectAbsolute(index) {
    if (displayModel.count === 0) return
    root.disarmPointer()
    root.cursorActive = true
    root.selectedIndex = Math.max(0, Math.min(index, displayModel.count - 1))
    resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
  }

  function disarmPointer() {
    pointerGate.reset()
  }

  function selectFromPointer(index, item, mouse) {
    if (!pointerGate.moved(item, mouse)) return
    root.cursorActive = true
    root.selectedIndex = index
  }

  function activateIndex(index) {
    if (index < 0 || index >= displayModel.count) return
    var row = displayModel.get(index)
    // Normal selection means: put this history item back into the clipboard.
    // Pasting into the focused application remains available via Shift+Enter.
    root.copySelected(row)
  }

  function pasteIndex(index) {
    if (index < 0 || index >= displayModel.count) return
    var row = displayModel.get(index)
    root.applySelected(row)
  }

  function copyIndex(index) {
    if (index < 0 || index >= displayModel.count) return
    var row = displayModel.get(index)
    root.copySelected(row)
  }

  function openIndex(index) {
    if (index < 0 || index >= displayModel.count) return
    var row = displayModel.get(index)
    root.openSelected(row)
  }

  function shellQuote(value) {
    return Util.shellQuote(String(value))
  }

  function copySelected(row) {
    if (!row) return
    if (row.entryType === "image" && row.path) {
      var imageCommand = "wl-copy --type " + shellQuote(row.mime || "image/png") + " < " + shellQuote(row.path)
      Quickshell.execDetached(["bash", "-c", imageCommand])
    } else if (row.fullText !== undefined && row.fullText !== null) {
      var textCommand = "printf %s " + shellQuote(row.fullText) + " | wl-copy"
      Quickshell.execDetached(["bash", "-c", textCommand])
    }
  }

  function applySelected(row) {
    if (!row) return
    root.copySelected(row)
    root.opened = false
    Quickshell.execDetached(["bash", "-c", "sleep 0.05; wtype -M shift -P Insert -p Insert -m shift 2>/dev/null || true"])
  }

  function openSelected(row) {
    if (!row) return
    root.opened = false
    if (row.entryType === "image" && row.path)
      Quickshell.execDetached(["xdg-open", row.path])
    else if (row.fullText)
      Quickshell.execDetached(["xdg-open", "data:text/plain," + encodeURIComponent(row.fullText)])
  }

  Component.onCompleted: initProc.running = true

  ListModel { id: displayModel }

  PointerMoveGate {
    id: pointerGate
    referenceItem: resultList
  }

  FileView {
    id: historyFile
    path: root.historyPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadHistory(text())
    onLoadFailed: root.loadHistory("[]")
    onFileChanged: reload()
  }

  // Reap watchers left behind by a previous shell instance, then start our
  // own. The pdeathsig on the watchers makes the kernel kill them whenever
  // the shell exits, however it exits, so no further lifecycle management.
  Process {
    id: initProc
    command: ["pkill", "-f", "wl-paste .*--watch .*/shell/plugins/clipboard/capture\\.sh"]
    onExited: {
      currentProc.running = true
      textWatchProc.running = true
      imageWatchProc.running = true
    }
  }

  Process {
    id: currentProc
    command: [root.captureScript]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.addClipboardJson(text)
    }
  }

  Process {
    id: textWatchProc
    command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "text", "--watch", root.captureScript, "text"]
    onExited: watchRestartTimer.restart()
    stdout: SplitParser {
      onRead: function(data) { root.addClipboardJson(data) }
    }
  }

  Process {
    id: imageWatchProc
    command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "image/png", "--watch", root.captureScript, "image/png"]
    onExited: watchRestartTimer.restart()
    stdout: SplitParser {
      onRead: function(data) { root.addClipboardJson(data) }
    }
  }

  // A watcher that dies takes clipboard history with it, silently: copying still
  // works, the picker still opens, and the old entries are all still there, so
  // nothing recorded until the next shell reload. Bring it back instead.
  Timer {
    id: watchRestartTimer
    interval: 1000
    repeat: false
    onTriggered: {
      if (!textWatchProc.running) textWatchProc.running = true
      if (!imageWatchProc.running) imageWatchProc.running = true
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    bar: root.bar
    owner: root
    open: root.opened && !!root.anchorItem
    focusTarget: keyCatcher

    padding: 0
    borderSpec: Border.surfaceSpec("clipboard", "panel-wrapper", "transparent", 0)
    contentWidth: Math.min(root.cardWidth, panel.availableCardWidth)
    contentHeight: Math.min(root.cardHeight, panel.availableCardHeight)
    gap: Style.space(5)

    BorderSurface {
      id: card
      anchors.fill: parent
      color: root.background
      borderSpec: root.borderSpec
      radius: 0
      clip: true

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: root.opened
        z: root.clearConfirmOpen ? 20 : 0

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (root.clearConfirmOpen) {
            if (clearConfirm.handleKey(event)) event.accepted = true
            return
          }

          if (event.key === Qt.Key_Escape) {
            root.close()
            event.accepted = true
          } else if (event.key === Qt.Key_Delete) {
            if (event.modifiers & Qt.ShiftModifier) root.requestClearHistory()
            else root.removeDisplayIndex(root.selectedIndex)
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.select(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.select(1)
            event.accepted = true
          } else if (event.key === Qt.Key_PageUp) {
            root.select(-6)
            event.accepted = true
          } else if (event.key === Qt.Key_PageDown) {
            root.select(6)
            event.accepted = true
          } else if (event.key === Qt.Key_Home) {
            root.selectAbsolute(0)
            event.accepted = true
          } else if (event.key === Qt.Key_End) {
            root.selectAbsolute(displayModel.count - 1)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.cursorActive && (event.modifiers & Qt.AltModifier)) root.openIndex(root.selectedIndex)
            else if (root.cursorActive && (event.modifiers & Qt.ShiftModifier)) root.pasteIndex(root.selectedIndex)
            else if (root.cursorActive) root.activateIndex(root.selectedIndex)
            else if (displayModel.count > 0) root.cursorActive = true
            event.accepted = true
          }
        }

        Component.onCompleted: {
          if (root.opened) Qt.callLater(function() { forceActiveFocus() })
        }

        ConfirmDialog {
          id: clearConfirm
          anchors.fill: parent
          opened: root.clearConfirmOpen
          z: 10
          message: "Delete entire clipboard history?"
          confirmText: "Delete"
          background: root.background
          foreground: root.foreground
          scrim: root.scrim
          selectedBackground: root.selectedBackground
          selectedText: root.selectedText
          fontFamily: root.fontFamily
          cornerRadius: root.cornerRadius
          onCanceled: root.cancelClearHistory()
          onConfirmed: root.confirmClearHistory()
        }
      }

      Column {
        anchors.fill: parent
        spacing: 0

        // Header — same visual grammar as the notification center:
        // icon, title, quiet subtitle, count.
        Item {
          width: parent.width
          height: Style.space(58)

          Row {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(16)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(10)

            Text {
              text: "󰅌"
              color: Color.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              spacing: Style.space(2)
              anchors.verticalCenter: parent.verticalCenter

              Text {
                text: "Clipboard"
                color: Color.text
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                text: "RECENT FRAGMENTS"
                color: Color.muted
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.1
              }
            }
          }

          Text {
            anchors.right: parent.right
            anchors.rightMargin: Style.space(16)
            anchors.verticalCenter: parent.verticalCenter
            text: root.history.length + (root.history.length === 1 ? " ITEM" : " ITEMS")
            color: Color.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }

        PanelSeparator {
          width: parent.width - Style.space(20)
          x: Style.space(10)
          foreground: Color.outline
        }

        // History — deliberately quiet until an item is selected.
        Item {
          width: parent.width
          height: Math.max(
            Style.space(150),
            parent.height - Style.space(58 + 1 + 48)
          )
          clip: true

          ListView {
            id: resultList
            anchors.fill: parent
            anchors.leftMargin: Style.space(12)
            anchors.rightMargin: Style.space(12)
            anchors.topMargin: Style.space(10)
            anchors.bottomMargin: Style.space(10)
            model: displayModel
            clip: true
            spacing: Style.space(5)
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            delegate: Rectangle {
              id: row
              required property int index
              required property string entryType
              required property string previewText
              required property string fullText
              required property string previewImage

              readonly property bool hasCursor: root.cursorActive && index === root.selectedIndex
              width: ListView.view.width
              height: root.rowHeight
              color: "transparent"

              Rectangle {
                anchors.fill: parent
                color: row.hasCursor
                  ? Util.alpha(Color.text, 0.075)
                  : Util.alpha(root.foreground, 0.025)
                border.width: Style.normalBorderWidth
                border.color: row.hasCursor
                  ? Util.alpha(Color.text, 0.16)
                  : Util.alpha(root.border, 0.22)
              }

              Rectangle {
                visible: row.hasCursor
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Style.space(1)
                color: Util.alpha(Color.text, 0.18)
              }

              Row {
                anchors.fill: parent
                anchors.leftMargin: Style.space(12)
                anchors.rightMargin: Style.space(12)
                spacing: Style.space(10)

                Item {
                  width: Style.space(30)
                  height: parent.height

                  Image {
                    visible: row.previewImage.length > 0
                    anchors.centerIn: parent
                    width: Style.space(24)
                    height: Style.space(24)
                    source: row.previewImage
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                  }

                  Text {
                    visible: !row.previewImage
                    anchors.centerIn: parent
                    text: row.entryType === "image"
                      ? "󰋩"
                      : row.entryType === "file"
                        ? "󰈔"
                        : "󰅌"
                    color: row.hasCursor ? root.selectedText : Color.accent
                    opacity: row.hasCursor ? 1 : 0.78
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }
                }

                Column {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width - Style.space(40)
                  spacing: Style.space(2)

                  Text {
                    width: parent.width
                    text: row.previewText
                    color: row.hasCursor ? root.selectedText : root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                  }

                  Text {
                    width: parent.width
                    text: row.entryType === "image"
                      ? "IMAGE"
                      : row.entryType === "file"
                        ? "FILE"
                        : "TEXT"
                    color: row.hasCursor ? root.selectedText : Color.muted
                    opacity: row.hasCursor ? 0.76 : 0.58
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    font.letterSpacing: 0.7
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onPositionChanged: function(mouse) {
                  root.selectFromPointer(row.index, row, mouse)
                }

                onClicked: {
                  root.cursorActive = true
                  root.selectedIndex = row.index
                  root.activateIndex(row.index)
                }
              }
            }
          }

          Column {
            anchors.centerIn: parent
            spacing: Style.space(7)
            visible: displayModel.count === 0

            Text {
              text: "󰅌"
              color: Color.accent
              opacity: 0.72
              font.family: root.fontFamily
              font.pixelSize: Style.font.displayLarge
              horizontalAlignment: Text.AlignHCenter
              width: Style.space(300)
            }

            Text {
              text: "Clipboard is empty"
              color: root.foreground
              opacity: 0.62
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
              width: Style.space(300)
            }
          }
        }

        PanelSeparator {
          width: parent.width - Style.space(20)
          x: Style.space(10)
          foreground: Color.outline
        }

        // Footer — one deliberate action, aligned to the same inset as the list.
        Item {
          width: parent.width
          height: Style.space(48)

          Button {
            id: clearButton
            anchors.right: parent.right
            anchors.rightMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(82)
            height: Style.space(30)
            text: "Clear"
            iconText: "󰆴"
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            bordered: true
            enabled: root.history.length > 0
            onClicked: root.requestClearHistory()
          }
        }
      }
    }
  }
}
