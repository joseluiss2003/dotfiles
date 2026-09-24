import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.clipboard"

  property bool popupOpen: false
  readonly property var clipboard: clipboardLoader.item

  function open() { popupOpen = true }
  function close() { popupOpen = false }
  function toggle() { popupOpen = !popupOpen }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Loader {
    id: clipboardLoader
    active: true
    source: Qt.resolvedUrl("Clipboard.qml")
    onLoaded: {
      item.anchorItem = button
      item.bar = root.bar
      item.opened = root.popupOpen
    }
  }

  onPopupOpenChanged: {
    if (!clipboard) return
    clipboard.anchorItem = button
    clipboard.bar = root.bar
    clipboard.opened = popupOpen
    if (popupOpen && typeof clipboard.open === "function") clipboard.open("{}")
    else if (!popupOpen && typeof clipboard.close === "function") clipboard.close()
  }

  onBarChanged: if (clipboard) clipboard.bar = root.bar
  
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰅍"
    opticalSize: Style.bar.iconCanvas
    fontSize: Style.bar.iconFont
    tooltipText: "Clipboard history"
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) root.close()
      else if (mouseButton === Qt.LeftButton) root.toggle()
    }
  }
}
