import QtQuick
import qs.core
import qs.ui

BarWidget {
  id: root

  moduleName: "swayp.theme-selector"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function toggleSelector() {
    if (!bar || !bar.shell) return
    if (typeof bar.shell.toggle === "function")
      bar.shell.toggle("swayp.theme-selector", "{}")
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰏘"
    opticalSize: Style.bar.iconCanvas
    fontSize: Style.bar.iconFont
    tooltipText: "Themes"
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton)
        root.toggleSelector()
    }
  }
}
