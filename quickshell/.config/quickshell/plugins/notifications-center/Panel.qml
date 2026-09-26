import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.I3
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "../notifications/components" as NotificationComponents
import "../notifications/NotificationLogic.js" as NotificationLogic

Panel {
  id: root

  moduleName: "omarchy.notification-center"
  ipcTarget: "omarchy.notification-center"

  bar: shell && shell.bar ? shell.bar : null

  property string preferredScreenName: ""

  readonly property var notificationBarSlot:
    bar && preferredScreenName !== "" && typeof bar.visibleModuleSlotOnScreen === "function"
      ? bar.visibleModuleSlotOnScreen("right", "omarchy.notification-center", preferredScreenName)
      : (bar && typeof bar.visibleModuleSlot === "function"
        ? bar.visibleModuleSlot("right", "omarchy.notification-center", null)
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
      ? shell.firstPartyServiceFor("omarchy.notifications")
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
  readonly property string fontFamily: Style.font.resolvedFamily

  readonly property var notificationPhrases: [
    "Catching signals",
    "Watching events",
    "Listening quietly",
    "Sorting alerts",
    "Keeping watch",
    "Reading the room"
  ]
  property int notificationPhraseIndex: Math.floor(Math.random() * notificationPhrases.length)
  readonly property string notificationPhrase:
    notificationPhrases[notificationPhraseIndex % notificationPhrases.length]

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
        root.notificationPhraseIndex = Math.floor(Math.random() * root.notificationPhrases.length)
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
    borderSpec: Border.surfaceSpec("notifications", "panel-wrapper", "transparent", 0)
    contentWidth: Math.min(Style.space(440), popup.availableCardWidth)
    contentHeight: Math.min(
      popup.availableCardHeight,
      card.headerHeight
        + Style.space(8)
        + Math.min(
          card.maxListHeight,
          Math.max(notificationList.contentHeight + Style.space(16), Style.space(72))
        )
        + Style.space(8)
        + Style.space(48)
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
        root.closePanel()
        event.accepted = true
      }

      Component.onCompleted: {
        if (root.opened)
          Qt.callLater(function() { forceActiveFocus() })
      }
    }

    BorderSurface {
      id: card
    
      readonly property int widthLimit: Style.space(440)
      readonly property int maxListHeight: Style.space(480)
      readonly property int headerHeight: Style.space(58)
    
      anchors.fill: parent
    
      color: Color.notifications.background
      borderSpec: Border.surfaceSpec(
        "notifications",
        "border",
        Color.notifications.border,
        Math.max(1, Style.space(2))
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
    
          Text {
            id: headerIcon
            textFormat: Text.PlainText
            text: root.dnd ? "󰂛" : "󰂚"
            color: root.dnd ? Color.urgent : Color.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.leftMargin: Style.space(14)
            anchors.verticalCenter: parent.verticalCenter
          }
    
          Column {
            anchors.left: headerIcon.right
            anchors.leftMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)
    
            Text {
              text: "Notifications"
              color: Color.notifications.text
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }
    
            Text {
              text: root.dnd ? "DO NOT DISTURB" : root.notificationPhrase.toUpperCase()
              color: Color.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.1
            }
          }
    
          Text {
            anchors.right: parent.right
            anchors.rightMargin: Style.space(14)
            anchors.verticalCenter: parent.verticalCenter
            text: root.notificationCount + (root.notificationCount === 1 ? " ALERT" : " ALERTS")
            color: Color.notifications.countdown
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }
    
        PanelSeparator {
          Layout.fillWidth: true
          Layout.leftMargin: Style.space(10)
          Layout.rightMargin: Style.space(10)
          foreground: Color.notifications.border
        }
    
        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: Math.min(
            card.maxListHeight,
            Math.max(notificationList.contentHeight + Style.space(16), Style.space(84))
          )
    
          ListView {
            id: notificationList
    
            anchors.fill: parent
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(10)
            anchors.topMargin: Style.space(8)
            anchors.bottomMargin: Style.space(8)
    
            model: centerModel
            spacing: Style.space(8)
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
              implicitHeight: notificationCard.implicitHeight
    
              NotificationComponents.NotificationCard {
                id: notificationCard
    
                width: parent.width
                app: row.app
                appIcon: row.appIcon
                summary: row.summary
                body: row.body
                image: row.image
                glyph: row.glyph
                urgency: row.urgency
                timestamp: row.timestamp
                cornerRadius: 0
                fontFamily: root.fontFamily
    
                // The service already owns action dispatch and lifecycle.
                // Reuse it rather than duplicating notification handling.
                onCloseRequested: {
                  if (!root.notificationService) return
    
                  var active = root.activeIndex(row.originalId, row.timestamp)
                  if (active >= 0)
                    root.notificationService.dismissPopup(active)
    
                  // Whether the notification is still live or already in
                  // history, the X means "remove this entry from the
                  // center". For a live popup the dismiss above queues its
                  // archive first; the history delete therefore runs after
                  // that archive and wins deterministically.
                  root.notificationService.removeHistoryEntry({
                    originalId: row.originalId,
                    timestamp: row.timestamp
                  })
                }
    
                onCardClicked: {
                  if (!root.notificationService) return
                  if (root.isActiveEntry(row.originalId, row.timestamp))
                    root.notificationService.invokePopupDefault(root.activeIndex(row.originalId, row.timestamp))
                  else
                    root.notificationService.focusApp({
                      app: row.app
                    })
                }
              }
            }
          }
    
          Column {
            anchors.centerIn: parent
            visible: root.notificationCount === 0
            spacing: Style.space(8)
    
            Text {
              width: parent.width
              text: "󰂚"
              color: Color.accent
              opacity: 0.75
              font.family: root.fontFamily
              font.pixelSize: Style.font.displayLarge
              horizontalAlignment: Text.AlignHCenter
            }
    
            Text {
              width: Style.space(300)
              text: root.dnd
                ? "Notifications are silenced"
                : "No notifications"
              color: Color.notifications.text
              opacity: 0.62
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }
    
        Item {
          id: footer
          Layout.fillWidth: true
          implicitHeight: Style.space(48)
    
          Row {
            anchors.fill: parent
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(10)
            anchors.bottomMargin: Style.space(8)
            spacing: Style.space(6)
    
            Button {
              width: (parent.width - parent.spacing) / 2
              text: root.dnd ? "Allow" : "Silence"
              iconText: root.dnd ? "󰂚" : "󰂛"
              foreground: Color.notifications.text
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              bordered: true
              onClicked: root.toggleDnd()
            }
    
            Button {
              width: (parent.width - parent.spacing) / 2
              text: "Clear"
              iconText: "󰆴"
              foreground: Color.notifications.text
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              bordered: true
              enabled: root.notificationCount > 0
              onClicked: root.clearAll()
            }
          }
        }
      }
    }
  }
}
