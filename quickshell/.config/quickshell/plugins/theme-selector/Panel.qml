import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui

Item {
  id: root

  readonly property string moduleName: "swayp.theme-selector"
  property bool opened: false

  property string home: Quickshell.env("HOME")
  property string themesDir: home + "/.config/swayp/themes"
  property string wallpapersRoot: home + "/.config/swayp/wallpapers"
  property string currentThemePath: home + "/.config/swayp/current-theme"

  property string selectedTheme: ""
  property string selectedWallpaper: ""
  property string preferredScreenName: ""
  property int themeIndex: 0
  property int wallpaperIndex: 0

  property color background: Color.menu.background
  property color foreground: Color.bar.text
  property color border: Color.foreground
  property color muted: Color.foreground

  readonly property int previewWidth: Style.space(760)
  readonly property int previewHeight: Style.space(470)
  readonly property int sideWidth: Style.space(250)
  readonly property int sideHeight: Style.space(350)
  readonly property int sideGap: Style.space(18)

  readonly property int themeCardHeight: Style.space(132)
  readonly property int themeCardWidth: Style.space(218)
  readonly property int themeSectionHeight: themeCardHeight
  readonly property int wallpaperCardHeight: Style.space(142)
  readonly property int wallpaperCardWidth: Style.space(320)
  readonly property int wallpaperSectionHeight: wallpaperCardHeight

  readonly property int cardWidth: Math.min(
    Math.max(Style.space(860), panel.width - Style.space(72)),
    Style.space(1120)
  )

  readonly property int contentHeight: Math.min(
    Math.max(Style.space(500), panel.height - Style.space(72)),
    Style.space(620)
  )

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
    root.opened = true
    root.selectedWallpaper = ""
    root.loadCurrentTheme()
    root.loadThemes()
    screenProc.running = true
    Qt.callLater(function() { focusCatcher.forceActiveFocus() })
  }

  function close() {
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
      if (themeList)
        themeList.positionViewAtIndex(root.themeIndex, ListView.Contain)
    })
  }

  function loadWallpapers() {
    wallpaperModel.clear()
    if (!root.selectedTheme) return

    wallpapersProc.running = false
    wallpapersProc.running = true
  }

  function parseWallpapers(raw) {
    wallpaperModel.clear()

    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var path = lines[i].trim()
      if (!path) continue

      wallpaperModel.append({
        path: path,
        url: Util.fileUrl(path),
        name: path.split("/").pop()
      })
    }

    if (wallpaperModel.count > 0) {
      root.wallpaperIndex = Math.max(
        0,
        Math.min(root.wallpaperIndex, wallpaperModel.count - 1)
      )

      if (!root.selectedWallpaper)
        root.selectedWallpaper = wallpaperModel.get(root.wallpaperIndex).path
    } else {
      root.wallpaperIndex = 0
      root.selectedWallpaper = ""
    }
  }

  function selectTheme(index) {
    if (index < 0 || index >= themeModel.count) return

    root.themeIndex = index
    root.selectedTheme = themeModel.get(index).id
    root.selectedWallpaper = ""
    root.wallpaperIndex = 0
    root.loadWallpapers()
  }

  function selectWallpaper(index) {
    if (index < 0 || index >= wallpaperModel.count) return

    root.wallpaperIndex = index
    root.selectedWallpaper = wallpaperModel.get(index).path
    Qt.callLater(function() {
      if (wallpaperList)
        wallpaperList.positionViewAtIndex(root.wallpaperIndex, ListView.Contain)
    })
  }

  function moveTheme(delta) {
    if (themeModel.count === 0) return

    var next = root.themeIndex + delta
    if (next < 0) next = themeModel.count - 1
    if (next >= themeModel.count) next = 0
    root.selectTheme(next)
  }

  function moveWallpaper(delta) {
    if (wallpaperModel.count === 0) return

    var next = root.wallpaperIndex + delta
    if (next < 0) next = wallpaperModel.count - 1
    if (next >= wallpaperModel.count) next = 0
    root.selectWallpaper(next)
  }

  function applySelection() {
    if (!root.selectedTheme || applyProc.running) return

    applyProc.command = ["swayp-theme-set", root.selectedTheme]
    applyProc.running = true
  }

  ListModel { id: themeModel }
  ListModel { id: wallpaperModel }

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
      "  preview=$(find \"$HOME/.config/swayp/wallpapers/$id\" -maxdepth 1 -type f " +
      "    \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.svg' \\) -print 2>/dev/null | sort | head -n1); " +
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
    id: wallpapersProc

    command: [
      "bash", "-c",
      "find \"$1\" -maxdepth 1 -type f " +
      "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.svg' \\) " +
      "-print 2>/dev/null | sort",
      "swayp-wallpaper-list",
      root.wallpapersRoot + "/" + root.selectedTheme
    ]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseWallpapers(this.text)
    }
  }
  Process {
    id: applyProc
    running: false

    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.close()
        notifyProc.running = true
      }
    }
  }

  Process {
    id: notifyProc
    command: ["notify-send", "SwayP", "Appearance applied"]
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
      color: Util.alpha(Color.background, 0.82)
      opacity: root.opened ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: 120
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

      Repeater {
        model: 5

        delegate: Item {
          id: themeCard

          readonly property int offset: index - 2
          readonly property int themeSlot: root.carouselIndex(offset)
          readonly property bool selected: offset === 0

          width: selected ? root.previewWidth : root.sideWidth
          height: selected ? root.previewHeight : root.sideHeight
          visible: themeSlot >= 0
          x: selected
            ? (carousel.width - width) / 2
            : (carousel.width - root.previewWidth) / 2
                + (offset < 0
                    ? offset * (root.sideWidth + root.sideGap) - root.sideGap
                    : root.previewWidth + root.sideGap + (offset - 1) * (root.sideWidth + root.sideGap))
          y: selected
            ? 0
            : (root.previewHeight - root.sideHeight) / 2
          z: selected ? 100 : 50 - Math.abs(offset)
          opacity: selected ? 1 : (Math.abs(offset) === 1 ? 0.72 : 0.34)
          scale: selected ? 1 : 0.96

          Behavior on x {
            NumberAnimation {
              duration: 150
              easing.type: Easing.OutCubic
            }
          }

          Behavior on opacity {
            NumberAnimation {
              duration: 150
              easing.type: Easing.OutCubic
            }
          }

          Behavior on scale {
            NumberAnimation {
              duration: 150
              easing.type: Easing.OutCubic
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
            color: Util.alpha(Color.background, 0.88)

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
          text: root.selectedTheme
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
          text: root.selectedTheme
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
}
