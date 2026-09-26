import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

// Sway-friendly popup surface.
//
// Unlike xdg PopupWindow, this uses one transparent full-screen layer-shell
// surface per open popup, which gives us reliable outside-click dismissal on
// Sway. The actual card stays in the same separate popup window: popups never
// become one combined control-center surface.
PanelWindow {
  id: root

  required property Item anchorItem
  required property QtObject bar
  property var owner: null
  property int margin: Style.gapsOut
  property int padding: Style.spacing.popupPadding
  property int contentWidth: Style.space(280)
  property int contentHeight: Style.space(200)
  property var borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
  property bool centerOnBar: false
  property bool alignToBarEdge: false
  property bool open: false
  property int gap: Style.gapsOut
  property bool popoutSwitching: false
  property bool popoutSwitchClosing: false

  default property alias contentItem: contentHolder.children

  readonly property var coordinatorKey: owner || root
  readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null
  readonly property string barPos: bar ? bar.position : "top"
  readonly property real screenW: screen ? screen.width : 0
  readonly property real screenH: screen ? screen.height : 0
  readonly property real barW: anchorWindow ? anchorWindow.width : screenW
  readonly property real barH: anchorWindow ? anchorWindow.height : 0
  readonly property real _barStripSize: bar ? Math.max(bar.barSize, (barPos === "top" || barPos === "bottom") ? barH : barW) + gap : 0

  function close() {
    if (owner && "close" in owner) owner.close()
    else root.open = false
  }

  function fittedContentWidth(width, cap) {
    var desired = Math.max(1, Number(width) || 1)
    var maxWidth = screenW > 0 ? Math.max(120, screenW - margin * 2) : desired
    if (cap !== undefined && Number(cap) > 0) maxWidth = Math.min(maxWidth, Number(cap))
    return Math.round(Math.min(desired, maxWidth))
  }

  function fittedContentHeight(implicitHeight, cap) {
    var inset = padding * 2 + Border.top(borderSpec) + Border.bottom(borderSpec)
    var desired = Math.max(inset, (Number(implicitHeight) || 0) + inset)
    var maxHeight = screenH > 0 ? Math.max(120, screenH - margin * 2) : desired
    if (cap !== undefined && Number(cap) > 0) maxHeight = Math.min(maxHeight, Number(cap))
    return Math.round(Math.min(desired, maxHeight))
  }

  function cappedContentHeight(height) {
    var desired = Math.max(padding * 2, Number(height) || padding * 2)
    var maxHeight = screenH > 0 ? Math.max(120, screenH - margin * 2) : desired
    return Math.round(Math.min(desired, maxHeight))
  }

  function barPoint(px, py) {
    if (barPos === "bottom") return Qt.point(px, py - (screenH - barH))
    if (barPos === "right") return Qt.point(px - (screenW - barW), py)
    return Qt.point(px, py)
  }

  function inBarRegion(px, py) {
    if (!bar) return false
    if (barPos === "bottom") return py >= screenH - _barStripSize
    if (barPos === "left") return px <= _barStripSize
    if (barPos === "right") return px >= screenW - _barStripSize
    return py <= _barStripSize
  }

  function pressTargetAt(px, py) {
    if (!anchorWindow || !anchorWindow.contentItem || !bar || !bar.clickTargets) return null
    var p = barPoint(px, py)
    var targets = bar.clickTargets
    for (var i = targets.length - 1; i >= 0; i--) {
      var target = targets[i]
      if (!target || !target.triggerPress || target.visible === false || target.opacity === 0 || !target.mapToItem) continue
      if (bar.targetBelongsToWindow && !bar.targetBelongsToWindow(target, anchorWindow)) continue
      var pos = anchorWindow.itemPosition(target)
      if (p.x >= pos.x && p.x <= pos.x + target.width && p.y >= pos.y && p.y <= pos.y + target.height)
        return target
    }
    return null
  }

  function forwardBarClick(px, py, button) {
    if (button !== Qt.LeftButton && button !== Qt.RightButton && button !== Qt.MiddleButton) return false
    var target = pressTargetAt(px, py)
    if (!target) return false
    target.triggerPress(button)
    return true
  }

  screen: anchorWindow ? anchorWindow.screen : null
  visible: open || card.opacity > 0 || popoutSwitching
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  WlrLayershell.namespace: "omarchy-popup-card"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  readonly property point anchorScreenPos: {
    if (!anchorItem || !anchorWindow) return Qt.point(0, 0)
    return anchorItem.mapToItem(anchorWindow.contentItem, 0, 0)
  }
  readonly property point cardOrigin: {
    if (!anchorItem || !bar) return Qt.point(margin, margin)
    var x = margin
    var y = margin

    if (centerOnBar && (barPos === "top" || barPos === "bottom")) {
      x = screenW / 2 - contentWidth / 2
      y = barPos === "bottom" ? screenH - barH - contentHeight - gap : barH + gap
    } else if (centerOnBar) {
      x = barPos === "left" ? barW + gap : screenW - barW - contentWidth - gap
      y = screenH / 2 - contentHeight / 2
    } else if (barPos === "bottom") {
      x = alignToBarEdge ? screenW - contentWidth - margin : anchorScreenPos.x + anchorItem.width / 2 - contentWidth / 2
      y = screenH - barH - contentHeight - gap
    } else if (barPos === "left") {
      x = barW + gap
      y = anchorScreenPos.y + anchorItem.height / 2 - contentHeight / 2
    } else if (barPos === "right") {
      x = screenW - barW - contentWidth - gap
      y = anchorScreenPos.y + anchorItem.height / 2 - contentHeight / 2
    } else {
      x = alignToBarEdge ? screenW - contentWidth - margin : anchorScreenPos.x + anchorItem.width / 2 - contentWidth / 2
      y = barH + gap
    }

    x = Math.max(margin, Math.min(x, screenW - contentWidth - margin))
    y = Math.max(margin, Math.min(y, screenH - contentHeight - margin))
    return Qt.point(Math.round(x), Math.round(y))
  }

  onOpenChanged: {
    if (!bar) return
    if (open) {
      popoutSwitchClosing = false
      popoutSwitching = bar.activePopout && bar.activePopout !== coordinatorKey
      bar.requestPopout(coordinatorKey)
      if (popoutSwitching) popoutSwitchTimer.restart()
    } else {
      popoutSwitchClosing = !!(owner && owner.popoutSwitchClosing)
      popoutSwitching = false
      if (bar.activePopout === coordinatorKey) bar.releasePopout(coordinatorKey)
      if (popoutSwitchClosing) closeSwitchTimer.restart()
    }
  }

  Timer {
    id: popoutSwitchTimer
    interval: 150
    onTriggered: root.popoutSwitching = false
  }

  Timer {
    id: closeSwitchTimer
    interval: 1
    onTriggered: root.popoutSwitchClosing = false
  }

  MouseArea {
    id: dismissArea
    anchors.fill: parent
    enabled: root.open
    acceptedButtons: Qt.AllButtons
    hoverEnabled: true

    onClicked: function(mouse) {
      if (root.inBarRegion(mouse.x, mouse.y) && root.forwardBarClick(mouse.x, mouse.y, mouse.button)) return
      root.close()
    }
  }

  BorderSurface {
    id: card
    x: root.cardOrigin.x
    y: root.cardOrigin.y
    width: root.contentWidth
    height: root.contentHeight
    color: Color.popups.background
    borderSpec: root.borderSpec
    padding: root.padding
    radius: 0
    opacity: root.open || root.popoutSwitching ? 1.0 : 0

    Behavior on opacity {
      enabled: !root.popoutSwitching && !root.popoutSwitchClosing
      NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

    Item {
      id: contentHolder
      anchors.fill: parent
      anchors.topMargin: card.contentTopInset
      anchors.rightMargin: card.contentRightInset
      anchors.bottomMargin: card.contentBottomInset
      anchors.leftMargin: card.contentLeftInset
    }
  }
}
