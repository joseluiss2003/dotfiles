import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.I3
import Quickshell.Wayland
import qs.core
import qs.ui
import "../notifications/components" as NotificationComponents
import "../notifications/NotificationLogic.js" as NotificationLogic

Panel {
  id: root

  moduleName: "swayp.notification-center"
  ipcTarget: "swayp.notification-center"

  bar: shell && shell.bar ? shell.bar : null

  property string preferredScreenName: ""

  readonly property var notificationBarSlot:
    bar && preferredScreenName !== "" && typeof bar.visibleModuleSlotOnScreen === "function"
      ? bar.visibleModuleSlotOnScreen("right", "swayp.notification-center", preferredScreenName)
      : (bar && typeof bar.visibleModuleSlot === "function"
        ? bar.visibleModuleSlot("right", "swayp.notification-center", null)
        : null)

  function open(payload) {
    preferredScreenName = ""
    if (payload) {
      try {
        var parsed = JSON.parse(String(payload))
        if (parsed && parsed.screenName) preferredScreenName = String(parsed.screenName)
      } catch (e) {
        console.warn("notification center: invalid open payload:", e)
      }
    }
    controller.show()
  }

  readonly property var notificationBarItem:
    notificationBarSlot
      ? (notificationBarSlot.activeItem || notificationBarSlot)
      : null

  // This panel deliberately consumes the existing notification service instead
  // of creating a second NotificationServer. The service owns lifetime,
  // persistence, DND and notification actions; this plugin is presentation.
  readonly property var notificationService:
    shell && typeof shell.firstPartyServiceFor === "function"
      ? shell.firstPartyServiceFor("swayp.notifications")
      : null

  readonly property var notifications:
    notificationService && notificationService.popupModel
      ? notificationService.popupModel
      : null

  ListModel {
    id: centerModel
  }

  readonly property int notificationCount: centerModel.count
  property bool historyReloadPending: false

  // The center is a standalone panel, not a child of the bar. Keep its
  // typography independent from bar lifetime while using the same resolved
  // font that the bar ultimately uses.
  readonly property string fontFamily: Style.font.family

  function activeRows() {
    var rows = []
    if (!notifications) return rows
    for (var i = 0; i < notifications.count; i++) {
      var row = notifications.get(i)
      if (row) rows.push({
        id: row.id,
        originalId: row.originalId,
        app: row.app,
        appIcon: row.appIcon,
        summary: row.summary,
        body: row.body,
        image: row.image,
        glyph: row.glyph || "",
        execArgv: row.execArgv || "",
        urgency: row.urgency,
        expireTimeout: row.expireTimeout || 0,
        timestamp: row.timestamp
      })
    }
    return rows
  }

  function activeIndex(originalId, timestamp) {
    if (!notifications) return -1
    for (var i = 0; i < notifications.count; i++) {
      var row = notifications.get(i)
      if (row && row.originalId === originalId && row.timestamp === timestamp) return i
    }
    return -1
  }

  function isActiveEntry(originalId, timestamp) {
    return activeIndex(originalId, timestamp) >= 0
  }

  function rebuildCenter(raw) {
    var live = activeRows()
    var rows = NotificationLogic.historyRows(
      raw,
      live,
      1,
      notificationService && notificationService.historyLimit
        ? notificationService.historyLimit
        : 10
    )

    centerModel.clear()
    for (var i = 0; i < rows.length; i++) centerModel.append(rows[i])
  }

  function reloadHistory() {
    if (!notificationService) return
    if (historyReader.running) {
      historyReloadPending = true
      return
    }

    historyReloadPending = false
    historyReader.command = [
      "bash", "-c",
      "awk 1 \"$1\"/*.json 2>/dev/null || true",
      "--",
      notificationService.historyDir
    ]
    historyReader.running = true
  }

  function clearAll() {
    if (notificationService)
      notificationService.clearAllNotifications()
  }

  readonly property bool dnd:
    notificationService ? !!notificationService.doNotDisturb : false

  property int selectedIndex: 0

  function plainNotificationText(value) {
    var text = String(value || "")
    text = text.replace(/<br\s*\/?\s*>/gi, " ")
    text = text.replace(/<[^>]*>/g, "")
    text = text.replace(/&nbsp;/gi, " ")
    text = text.replace(/&amp;/gi, "&")
    text = text.replace(/&lt;/gi, "<")
    text = text.replace(/&gt;/gi, ">")
    text = text.replace(/\bhttps?:\/\/\S+/gi, "")
    text = text.replace(/\bwww\.\S+/gi, "")
    text = text.replace(/\b(?:[a-z0-9-]+\.)+(?:com|net|org|io|es|dev|cloud|app|co|uk|de|fr|it)\b/gi, "")
    return text.replace(/\s+/g, " ").trim()
  }

  function formatTime(timestamp) {
    var date = new Date(Number(timestamp) || 0)
    if (!isFinite(date.getTime())) return "--:--"
    return Qt.formatTime(date, "HH:mm")
  }

  function clampSelection() {
    if (centerModel.count <= 0) {
      selectedIndex = 0
      return
    }
    selectedIndex = Math.max(0, Math.min(selectedIndex, centerModel.count - 1))
    Qt.callLater(function() {
      if (notificationList && selectedIndex >= 0)
        notificationList.positionViewAtIndex(selectedIndex, ListView.Contain)
    })
  }

  function moveSelection(delta) {
    if (centerModel.count <= 0) return
    selectedIndex = (selectedIndex + delta + centerModel.count) % centerModel.count
    Qt.callLater(function() {
      notificationList.positionViewAtIndex(selectedIndex, ListView.Contain)
    })
  }

  function openSelected() {
    if (!root.notificationService || selectedIndex < 0 || selectedIndex >= centerModel.count) return
    var row = centerModel.get(selectedIndex)
    if (!row) return
    var active = root.activeIndex(row.originalId, row.timestamp)
    if (active >= 0)
      root.notificationService.invokePopupDefault(active)
    else
      root.notificationService.focusApp({ app: row.app })
  }

  function clearEntry(originalId, timestamp) {
    if (!root.notificationService) return
    var active = root.activeIndex(originalId, timestamp)
    if (active >= 0)
      root.notificationService.dismissPopup(active)
    root.notificationService.removeHistoryEntry({
      originalId: originalId,
      timestamp: timestamp
    })
  }

  function clearSelected() {
    if (selectedIndex < 0 || selectedIndex >= centerModel.count) return
    var row = centerModel.get(selectedIndex)
    if (!row) return
    root.clearEntry(row.originalId, row.timestamp)
  }

  function toggleDnd() {
    if (notificationService)
      notificationService.setDoNotDisturb(!notificationService.doNotDisturb)
  }


  function closePanel() {
    root.close()
  }

  Process {
    id: historyReader
    running: false

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.rebuildCenter(text)
        root.clampSelection()
        if (root.historyReloadPending) {
          root.historyReloadPending = false
          Qt.callLater(root.reloadHistory)
        }
      }
    }
  }

  Connections {
    target: root.notificationService

    function onHistoryChanged() {
      root.reloadHistory()
    }
  }

  Connections {
    target: root

    function onNotificationServiceChanged() {
      root.reloadHistory()
    }
  }

  Connections {
    target: root.notifications

    function onCountChanged() {
      root.reloadHistory()
    }

    function onDataChanged() {
      root.reloadHistory()
    }
  }

  Connections {
    target: root
    function onOpenedChanged() {
      if (root.opened) {
        root.selectedIndex = 0
        root.reloadHistory()
      }
    }
  }

  Component.onCompleted: root.reloadHistory()

  KeyboardPanel {
    id: popup
    anchorItem: root.notificationBarItem
    owner: root
    bar: root.bar
    open: root.opened && !!root.notificationBarItem
    focusTarget: focusCatcher

    padding: 0
    drawBackground: false
    borderSpec: Border.surfaceSpec("notifications", "panel-wrapper", "transparent", 0)
    contentWidth: Math.min(Style.space(400), popup.availableCardWidth)
    contentHeight: Math.min(
      popup.availableCardHeight,
      card.headerHeight
        + Style.spacing.controlGap
        + (
          root.notificationCount === 0
            ? Style.space(112)
            : Math.min(
                card.maxListHeight,
                Math.max(notificationList.contentHeight + Style.space(16), Style.space(72))
              )
        )
        + Style.spacing.controlGap
        + card.borderTop + card.borderBottom
    )

    Item {
      id: focusCatcher
      anchors.fill: parent
      focus: root.opened

      Keys.onEscapePressed: function(event) {
        root.closePanel()
        event.accepted = true
      }

      Keys.onReturnPressed: function(event) {
        root.openSelected()
        event.accepted = true
      }

      Keys.onUpPressed: function(event) {
        root.moveSelection(-1)
        event.accepted = true
      }

      Keys.onDownPressed: function(event) {
        root.moveSelection(1)
        event.accepted = true
      }

      Keys.onDeletePressed: function(event) {
        root.clearSelected()
        event.accepted = true
      }

      Keys.onPressed: function(event) {
        if (event.text.toLowerCase() === "d") {
          root.toggleDnd()
          event.accepted = true
        } else if (event.text.toLowerCase() === "c") {
          root.clearAll()
          event.accepted = true
        }
      }

      Component.onCompleted: {
        if (root.opened)
          Qt.callLater(function() { forceActiveFocus() })
      }
    }

    BorderSurface {
      id: card
    
      readonly property int widthLimit: Style.space(400)
      readonly property int maxListHeight: Style.space(400)
      readonly property int headerHeight: Style.popup.headerHeight
    
      anchors.fill: parent
    
      color: Color.notifications.background
      borderSpec: Border.surfaceSpec(
        "notifications",
        "border",
        Color.notifications.border,
        Math.max(1, Style.spacing.compactGap)
      )
      radius: 0
      clip: true
    
      ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: card.borderTop
        anchors.leftMargin: card.borderLeft
        anchors.rightMargin: card.borderRight
        anchors.bottomMargin: card.borderBottom
        spacing: 0
    
        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: card.headerHeight

          PanelCliHeader {
            anchors.fill: parent
            title: "Notifications"
            status: root.dnd
              ? "DO NOT DISTURB · " + root.notificationCount + " EVENTS"
              : root.notificationCount + (root.notificationCount === 1 ? " EVENT" : " EVENTS")
            foreground: Color.notifications.text
            fontFamily: root.fontFamily
            trailingControl: Component {
              Text {
                text: "CLEAR"
                color: root.notificationCount > 0 ? Color.accent : Color.foreground
                opacity: root.notificationCount > 0 ? 1.0 : 0.45
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true

                MouseArea {
                  anchors.fill: parent
                  enabled: root.notificationCount > 0
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.clearAll()
                }
              }
            }
          }
        }

        PanelSeparator {
          Layout.fillWidth: true
          Layout.leftMargin: Style.popup.contentInset
          Layout.rightMargin: Style.popup.contentInset
          foreground: Color.notifications.border
        }
    
        Item {
          Layout.fillWidth: true
          visible: root.notificationCount > 0
          Layout.preferredHeight: Math.min(
            card.maxListHeight,
            Math.max(notificationList.contentHeight + Style.space(16), Style.space(84))
          )
    
          ListView {
            id: notificationList
    
            anchors.fill: parent
            anchors.leftMargin: Style.popup.contentInset
            anchors.rightMargin: Style.popup.contentInset
            anchors.topMargin: Style.spacing.controlGap
            anchors.bottomMargin: Style.spacing.controlGap
    
            model: centerModel
            spacing: Style.spacing.md
            clip: true
            boundsBehavior: Flickable.StopAtBounds
    
            delegate: Item {
              id: row

              required property int index
              required property int originalId
              required property string app
              required property string appIcon
              required property string summary
              required property string body
              required property string image
              required property string glyph
              required property int urgency
              required property double timestamp

              width: notificationList.width
              height: rowColumn.implicitHeight

              Column {
                id: rowColumn
                width: parent.width
                spacing: Style.spacing.xs

                CursorSurface {
                  width: parent.width
                  height: Math.max(Style.space(30), Style.font.body)
                  hasCursor: root.selectedIndex === row.index
                  foreground: Color.notifications.text
                  fill: "transparent"
                  currentFill: "transparent"

                  Text {
                    id: urgencyMark
                    visible: row.urgency === 2
                    anchors.left: parent.left
                    anchors.leftMargin: Style.spacing.md + Style.spacing.md
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.PlainText
                    text: "!"
                    color: Color.urgent
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }

                  Text {
                    id: appName
                    anchors.left: urgencyMark.visible ? urgencyMark.right : parent.left
                    anchors.leftMargin: urgencyMark.visible ? Style.spacing.xs : Style.spacing.md + Style.spacing.md
                    anchors.right: timeLabel.left
                    anchors.rightMargin: Style.spacing.md
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.PlainText
                    text: String(row.app || "SYSTEM").toUpperCase()
                    color: Color.notifications.text
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                    elide: Text.ElideRight
                  }

                  Text {
                    id: timeLabel
                    anchors.right: closeAction.left
                    anchors.rightMargin: Style.spacing.md
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.PlainText
                    text: root.formatTime(row.timestamp)
                    color: Color.notifications.text
                    opacity: 0.82
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }

                  Text {
                    id: closeAction
                    anchors.right: parent.right
                    anchors.rightMargin: Style.spacing.md
                    anchors.verticalCenter: parent.verticalCenter
                    text: "×"
                    color: root.selectedIndex === row.index ? Color.accent : Color.notifications.text
                    opacity: root.selectedIndex === row.index ? 1.0 : 0.65
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true

                    MouseArea {
                      anchors.fill: parent
                      anchors.margins: -Style.spacing.xs
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.clearEntry(row.originalId, row.timestamp)
                    }
                  }

                  MouseArea {
                    anchors.left: parent.left
                    anchors.right: closeAction.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    hoverEnabled: true
                    onContainsMouseChanged: if (containsMouse) root.selectedIndex = row.index
                    onClicked: root.openSelected()
                  }
                }
                Text {
                  width: parent.width
                  leftPadding: Style.spacing.md + Style.spacing.md
                  rightPadding: Style.spacing.md
                  textFormat: Text.PlainText
                  text: {
                    var title = String(row.summary || "").trim()
                    var body = root.plainNotificationText(row.body)
                    if (title.length > 0 && body.length > 0) return title + " · " + body
                    return title.length > 0 ? title : (body.length > 0 ? body : "—")
                  }
                  color: Color.notifications.text
                  opacity: 0.76
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  maximumLineCount: 1
                }
              }
            }
          }
        }

        Item {
          Layout.fillWidth: true
          visible: root.notificationCount === 0
          Layout.preferredHeight: Style.space(112)

          Column {
            anchors.centerIn: parent
            spacing: Style.spacing.controlGap

            Text {
              width: Style.space(300)
              text: "󰂚"
              color: Color.foreground
              opacity: 0.75
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              width: Style.space(300)
              text: root.dnd
                ? "NOTIFICATIONS SILENCED"
                : "NO NOTIFICATIONS"
              color: Color.notifications.text
              opacity: Style.opacity.mutedText
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }
    
        
        }
      }
    }
  }
