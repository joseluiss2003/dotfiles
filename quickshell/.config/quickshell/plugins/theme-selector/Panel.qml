import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.core
import qs.ui

Item {
  id: root

  readonly property string moduleName: "swayp.theme-selector"
  property bool opened: false

  property string home: Quickshell.env("HOME")
  property string themesDir: home + "/.config/swayp/themes"
  property string currentThemePath: home + "/.config/swayp/current-theme"

  property string selectedTheme: ""
  property string preferredScreenName: ""
  property int themeIndex: 0
  property bool applying: false
  property bool layoutSettled: false

  property color foreground: Color.bar.text
  property color muted: Color.foreground

  readonly property int previewWidth: Style.space(760)
  // Theme previews are 16:9 (1920x1080 class). Keep the cards at the
  // source aspect ratio so PreserveAspectCrop never cuts the artwork.
  readonly property int previewHeight: Math.round(previewWidth * 9 / 16)
  readonly property int sideWidth: Style.space(250)
  readonly property int sideHeight: Math.round(sideWidth * 9 / 16)
  readonly property int sideGap: Style.space(18)
  readonly property int carouselSlots: themeModel.count >= 5 ? 5 : (themeModel.count > 1 ? 3 : 1)
  readonly property int carouselCenter: Math.floor(carouselSlots / 2)

  readonly property var targetScreen: {
    var screens = Quickshell.screens || []
    if (root.preferredScreenName) {
      for (var i = 0; i < screens.length; i++) {
        if (String(screens[i].name || "") === root.preferredScreenName)
          return screens[i]
      }
    }
    return screens.length > 0 ? screens[0] : null
  }

  function open(payloadJson) {
    root.layoutSettled = false
    root.opened = true
    root.loadCurrentTheme()
    root.loadThemes()
    screenProc.running = true
    Qt.callLater(function() { focusCatcher.forceActiveFocus() })
  }

  function close() {
    root.layoutSettled = false
    root.opened = false
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open("{}")
  }

  function loadCurrentTheme() {
    currentThemeFile.reload()
  }

  function loadThemes() {
    themesProc.running = false
    themesProc.running = true
  }

  function parseThemes(raw) {
    themeModel.clear()

    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].split("\t")
      if (parts.length < 4) continue

      themeModel.append({
        id: parts[0],
        name: parts[1],
        description: parts[2],
        preview: parts[3]
      })
    }

    if (themeModel.count === 0) return

    var found = -1
    for (var j = 0; j < themeModel.count; j++) {
      if (themeModel.get(j).id === root.selectedTheme) {
        found = j
        break
      }
    }

    root.themeIndex = found >= 0 ? found : 0
    root.selectedTheme = themeModel.get(root.themeIndex).id

    Qt.callLater(function() {
      if (root.opened && themeModel.count > 0)
        root.layoutSettled = true
    })
  }

  function selectTheme(index) {
    if (index < 0 || index >= themeModel.count) return

    root.themeIndex = index
    root.selectedTheme = themeModel.get(index).id
  }

  function moveTheme(delta) {
    if (themeModel.count === 0) return

    var next = root.themeIndex + delta
    if (next < 0) next = themeModel.count - 1
    if (next >= themeModel.count) next = 0
    root.selectTheme(next)
  }

  function carouselIndex(offset) {
    if (themeModel.count === 0) return -1

    var value = (root.themeIndex + offset) % themeModel.count
    if (value < 0) value += themeModel.count
    return value
  }

  // Circular carousel offset: each theme keeps its own delegate so changing
  // selection moves the actual cards through the carousel instead of swapping
  // their contents in fixed slots. This gives the theme picker the same
  // sliding motion as the wallpaper picker.
  function carouselOffset(index) {
    var count = themeModel.count
    if (count <= 1) return 0

    var delta = index - root.themeIndex
    var half = Math.floor(count / 2)

    if (delta > half) delta -= count
    if (delta < -half) delta += count

    return delta
  }

  function applySelection() {
    if (!root.selectedTheme || applyProc.running) return

    root.applying = true
    applyProc.command = [
      "bash",
      "-lc",
      "exec " + root.home + "/.local/bin/swayp-theme-set " + JSON.stringify(root.selectedTheme) +
      " >> " + root.home + "/.cache/swayp-theme-selector.log 2>&1"
    ]
    applyProc.running = true
    // Start the process before closing the panel so the Process object remains
    // owned by a live selector instance while the theme transition runs.
    root.close()
  }

  ListModel { id: themeModel }

  FileView {
    id: currentThemeFile
    path: root.currentThemePath
    watchChanges: true
    printErrors: false

    onLoaded: {
      var value = String(currentThemeFile.text() || "").trim()
      if (value.length > 0)
        root.selectedTheme = value
    }
  }

  Process {
    id: screenProc

    command: [
      "bash", "-c",
      "swaymsg -t get_workspaces -r 2>/dev/null | " +
      "jq -r '.[] | select(.focused == true) | .output' 2>/dev/null || true"
    ]

    stdout: StdioCollector {
      waitForEnd: true

      onStreamFinished: {
        var value = String(this.text || "").trim()
        if (value.length > 0)
          root.preferredScreenName = value
      }
    }
  }

  Process {
    id: themesProc

    command: [
      "bash", "-c",
      "for dir in \"$1\"/*; do " +
      "  [ -d \"$dir\" ] || continue; " +
      "  id=$(basename \"$dir\"); " +
      "  name=$(awk -F= '/^[[:space:]]*name[[:space:]]*=/{sub(/^[[:space:]]*/, \"\", $2); sub(/[[:space:]]*$/, \"\", $2); gsub(/^\"|\"$/, \"\", $2); print $2; exit}' \"$dir/theme.toml\" 2>/dev/null); " +
      "  [ -n \"$name\" ] || name=\"$id\"; " +
      "  desc=$(awk -F= '/^[[:space:]]*description[[:space:]]*=/{sub(/^[[:space:]]*/, \"\", $2); sub(/[[:space:]]*$/, \"\", $2); gsub(/^\"|\"$/, \"\", $2); print $2; exit}' \"$dir/theme.toml\" 2>/dev/null); " +
      "  preview=$(find \"$dir\" -maxdepth 1 -type f " +
      "    \\( -iname 'preview.jpg' -o -iname 'preview.jpeg' -o -iname 'preview.png' -o -iname 'preview.webp' -o -iname 'preview.svg' \\) -print 2>/dev/null | sort | head -n1); " +
      "  if [ -z \"$preview\" ]; then " +
      "    preview=$(find \"$HOME/.config/swayp/wallpapers/$id\" -maxdepth 1 -type f " +
      "      \\( -iname '01.jpg' -o -iname '01.jpeg' -o -iname '01.png' -o -iname '01.webp' -o -iname '01.svg' \\) -print 2>/dev/null | sort | head -n1); " +
      "  fi; " +
      "  printf '%s\\t%s\\t%s\\t%s\\n' \"$id\" \"$name\" \"$desc\" \"$preview\"; " +
      "done 2>/dev/null | sort",
      "swayp-theme-list",
      root.themesDir
    ]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseThemes(this.text)
    }
  }
  Process {
    id: applyProc
    running: false

    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.applying = false
        notifyProc.running = true
      } else {
        root.applying = false
      }
    }
  }

  Process {
    id: notifyProc
    command: ["notify-send", "SwayP", "Theme applied"]
  }

  PanelWindow {
    id: panel

    screen: root.targetScreen
    visible: root.opened

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "swayp-theme-selector"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus:
      root.opened
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: Util.alpha(Color.fullscreen.scrim, 0.82)
      opacity: root.opened ? (root.applying ? 0.34 : 1) : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Style.fullscreen.scrimDuration
          easing.type: Easing.OutCubic
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.opened
      onClicked: root.close()
    }

    Item {
      id: focusCatcher
      anchors.fill: parent
      focus: root.opened

      Keys.priority: Keys.BeforeItem

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.close()
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_Left) {
          root.moveTheme(-1)
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_Right) {
          root.moveTheme(1)
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.applySelection()
          event.accepted = true
        }
      }

      Component.onCompleted: Qt.callLater(function() { forceActiveFocus() })
    }

    Item {
      id: carousel
      anchors.centerIn: parent
      width: Math.min(
        parent.width - Style.space(48),
        root.previewWidth + root.sideWidth * 2 + root.sideGap * 2
      )
      height: root.previewHeight + Style.space(110)
      opacity: root.layoutSettled && !root.applying ? 1 : 0
      scale: root.layoutSettled && !root.applying ? 1 : 0.985

      Behavior on opacity {
        NumberAnimation {
          duration: Style.fullscreen.itemDuration
          easing.type: Easing.OutQuint
        }
      }

      Behavior on scale {
        NumberAnimation {
          duration: Style.fullscreen.settleDuration
          easing.type: Easing.OutQuint
        }
      }

      Repeater {
        model: themeModel

        delegate: Item {
          id: themeCard

          required property int index

          // Keep the legacy body bindings while each theme has its own delegate.
          readonly property int themeSlot: index
          readonly property int relativeIndex: root.carouselOffset(index)
          readonly property bool nearby: Math.abs(relativeIndex) <= root.carouselCenter
          readonly property bool selected: index === root.themeIndex
          readonly property var themeData: themeModel.get(index)

          visible: nearby

          width: selected ? root.previewWidth : root.sideWidth
          height: selected ? root.previewHeight : root.sideHeight
          x: selected
            ? (carousel.width - root.previewWidth) / 2
            : (relativeIndex < 0
                ? (carousel.width - root.previewWidth) / 2
                    + relativeIndex * (root.sideWidth + root.sideGap)
                    - root.sideGap
                : (carousel.width - root.previewWidth) / 2
                    + root.previewWidth + root.sideGap
                    + (relativeIndex - 1) * (root.sideWidth + root.sideGap))
          y: selected
            ? 0
            : (root.previewHeight - root.sideHeight) / 2
          z: selected ? 100 : 50 - Math.abs(relativeIndex)
          opacity: selected ? 1 : (Math.abs(relativeIndex) === 1 ? 0.72 : 0.34)
          scale: selected ? 1 : 0.96

          Behavior on x {
            enabled: root.layoutSettled
            NumberAnimation {
              duration: Style.fullscreen.itemDuration
              easing.type: Easing.OutQuint
            }
          }

          Behavior on y {
            enabled: root.layoutSettled
            NumberAnimation {
              duration: Style.fullscreen.itemDuration
              easing.type: Easing.OutQuint
            }
          }

          Behavior on width {
            enabled: root.layoutSettled
            NumberAnimation {
              duration: Style.fullscreen.itemDuration
              easing.type: Easing.OutQuint
            }
          }

          Behavior on height {
            enabled: root.layoutSettled
            NumberAnimation {
              duration: Style.fullscreen.itemDuration
              easing.type: Easing.OutQuint
            }
          }

          Behavior on opacity {
            enabled: root.layoutSettled
            NumberAnimation {
              duration: Style.fullscreen.itemDuration
              easing.type: Easing.OutQuint
            }
          }

          Behavior on scale {
            enabled: root.layoutSettled
            NumberAnimation {
              duration: Style.fullscreen.itemDuration
              easing.type: Easing.OutQuint
            }
          }

          Rectangle {
            anchors.fill: parent
            color: Color.background
            border.width: selected ? 2 : 1
            border.color: selected
              ? root.foreground
              : Util.alpha(root.foreground, 0.28)
            clip: true
          }

          Image {
            anchors.fill: parent
            anchors.margins: selected ? 2 : 1

            source: {
              if (themeSlot < 0 || themeSlot >= themeModel.count)
                return ""
              var path = String(themeModel.get(themeSlot).preview || "")
              return path.length > 0 ? Util.fileUrl(path) : ""
            }

            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
          }

          Rectangle {
            anchors.fill: parent
            color: selected
              ? "transparent"
              : Util.alpha(Color.background, 0.40)
          }

          Rectangle {
            visible: !selected
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Style.space(52)
            color: Util.alpha(Color.fullscreen.background, 0.88)

            Text {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: Style.space(10)
              anchors.rightMargin: Style.space(10)

              text: themeSlot >= 0 && themeSlot < themeModel.count
                ? themeModel.get(themeSlot).name
                : ""

              color: root.foreground
              font.family: Style.font.resolvedFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: {
              if (themeSlot < 0) return
              if (selected) root.applySelection()
              else root.selectTheme(themeSlot)
            }
          }
        }
      }

      Column {
        anchors.top: carousel.bottom
        anchors.topMargin: Style.space(18)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(4)

        Text {
          width: carousel.width
          text: themeModel.count > 0 && root.themeIndex >= 0 && root.themeIndex < themeModel.count
            ? themeModel.get(root.themeIndex).name
            : "SELECT A THEME"

          color: root.foreground
          font.family: Style.font.resolvedFamily
          font.pixelSize: Style.font.display
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
        }

        Text {
          width: carousel.width
          text: themeModel.count > 0 && root.themeIndex >= 0 && root.themeIndex < themeModel.count
            ? (themeModel.get(root.themeIndex).description || themeModel.get(root.themeIndex).id)
            : ""

          color: root.muted
          font.family: Style.font.resolvedFamily
          font.pixelSize: Style.font.bodySmall
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
        }

        Text {
          width: carousel.width
          text: applyProc.running
            ? "APPLYING…"
            : "← →  SELECT    ENTER  APPLY    ESC  CLOSE"

          color: root.muted
          font.family: Style.font.resolvedFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }
}
