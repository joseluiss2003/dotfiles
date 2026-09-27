import QtQuick
import qs.core
import qs.ui

BarWidget {
  id: root
  moduleName: "swayp.theme-selector"
  property bool popupOpen: false
  readonly property var selector: selectorLoader.item
  function open() { popupOpen = true }
  function close() { popupOpen = false }
  function toggle() { popupOpen = !popupOpen }
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Loader {
    id: selectorLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    onLoaded: {
      item.anchorItem = button
      item.bar = root.bar
      item.opened = root.popupOpen
    }
  }

  onPopupOpenChanged: {
    if (!selector) return
    selector.anchorItem = button
    selector.bar = root.bar
    if (popupOpen && typeof selector.open === "function") selector.open("{}")
    else if (!popupOpen && typeof selector.close === "function") selector.close()
  }

  onBarChanged: if (selector) selector.bar = root.bar

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰏘"
    opticalSize: Style.bar.iconCanvas
    fontSize: Style.bar.iconFont
    tooltipText: "Themes"
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) root.close()
      else if (mouseButton === Qt.LeftButton) root.toggle()
    }
  }
}
