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
  property string currentThemePath: home + "/.local/state/swayp/current/theme.name"

  property string selectedTheme: ""
  property string selectedWallpaper: ""
  property string preferredScreenName: ""
  property int themeIndex: 0
  property int wallpaperIndex: 0

  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property color muted: Color.muted

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
    root.selectedWallpaper = ""
    root.loadWallpapers()
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

    var wallpaper = root.selectedWallpaper

    applyProc.command = [
      "bash", "-c",
      "set -eu; " +
      "if [ -n \"$2\" ]; then " +
      "  awww img --transition-type center \"$2\"; " +
      "  mkdir -p \"$HOME/.local/state/swayp/current\"; " +
      "  ln -sfn \"$2\" \"$HOME/.local/state/swayp/current/background\"; " +
      "fi; " +
      "swayp-theme-set \"$1\"",
      "swayp-theme-selector",
      root.selectedTheme,
      wallpaper
    ]

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

    WlrLayershell.namespace: "swayp-appearance"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus:
      root.opened
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore

    MouseArea {
      anchors.fill: parent
      enabled: root.opened
      onClicked: root.close()
    }

    Rectangle {
      anchors.fill: parent
      color: Util.alpha(root.background, 0.82)
      opacity: root.opened ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: 120
          easing.type: Easing.OutCubic
        }
      }
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

        if (event.key === Qt.Key_Up) {
          root.moveWallpaper(-1)
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_Down) {
          root.moveWallpaper(1)
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.applySelection()
          event.accepted = true
        }
      }

      Component.onCompleted: Qt.callLater(function() {
        forceActiveFocus()
      })
    }

    BorderSurface {
      id: card

      width: root.cardWidth
      height: root.contentHeight

      anchors.centerIn: parent

      color: root.background
      borderSpec: Border.surfaceSpec(
        "theme-selector",
        "card",
        root.border,
        Math.max(1, Style.space(1))
      )
      radius: 0
      clip: true

      scale: root.opened ? 1 : 0.985

      Behavior on scale {
        NumberAnimation {
          duration: 140
          easing.type: Easing.OutCubic
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(20)
        spacing: Style.space(12)

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(58)

          Text {
            id: appearanceIcon

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            text: "󰏘"
            color: root.foreground
            font.family: Style.font.resolvedFamily
            font.pixelSize: Style.font.display
          }

          Column {
            anchors.left: appearanceIcon.right
            anchors.leftMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Appearance"
              color: root.foreground
              font.family: Style.font.resolvedFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              text: "THEME + CURATED WALLPAPER"
              color: root.muted
              font.family: Style.font.resolvedFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.1
            }
          }

          Text {
            anchors.right: closeHint.left
            anchors.rightMargin: Style.space(14)
            anchors.verticalCenter: parent.verticalCenter

            text: root.selectedTheme
              ? root.selectedTheme.toUpperCase()
              : "SELECT A THEME"

            color: root.foreground
            font.family: Style.font.resolvedFamily
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            opacity: 0.9
          }

          Text {
            id: closeHint

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            text: "ESC"
            color: root.muted
            font.family: Style.font.resolvedFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1
          }
        }

        PanelSeparator {
          Layout.fillWidth: true
          foreground: root.border
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(24)

          Text {
            text: "THEMES"
            color: root.muted
            font.family: Style.font.resolvedFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
          }

          Item { Layout.fillWidth: true }

          Text {
            text: themeModel.count > 0
              ? root.themeIndex + 1 + " / " + themeModel.count
              : "LOADING"

            color: root.muted
            font.family: Style.font.resolvedFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }

        ListView {
          id: themeList

          Layout.fillWidth: true
          Layout.preferredHeight: root.themeSectionHeight

          orientation: ListView.Horizontal
          spacing: Style.space(8)
          clip: true
          interactive: true
          boundsBehavior: Flickable.StopAtBounds
          snapMode: ListView.SnapToItem
          currentIndex: root.themeIndex
          model: themeModel

          onCurrentIndexChanged: {
            if (currentIndex >= 0 && currentIndex !== root.themeIndex)
              root.selectTheme(currentIndex)
          }

          delegate: Item {
              id: themeCard

              width: root.themeCardWidth
              height: root.themeCardHeight

              property bool chosen: index === root.themeIndex
              property bool hovered: false

              scale: hovered ? 1.012 : 1

              Behavior on scale {
                NumberAnimation {
                  duration: 100
                  easing.type: Easing.OutCubic
                }
              }

              Rectangle {
                anchors.fill: parent
                color: chosen
                  ? Util.alpha(root.foreground, 0.10)
                  : Util.alpha(root.foreground, 0.025)

                border.width: chosen ? 2 : 1
                border.color: chosen
                  ? root.foreground
                  : Util.alpha(root.foreground, hovered ? 0.36 : 0.14)
              }

              Image {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                anchors.margins: 1
                height: Style.space(88)

                source: model.preview ? Util.fileUrl(model.preview) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true

                opacity: chosen ? 0.96 : 0.82
              }

              Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                height: parent.height - Style.space(88)

                color: chosen
                  ? Util.alpha(root.background, 0.90)
                  : Util.alpha(root.background, 0.96)

                Text {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.margins: Style.space(9)

                  text: model.name
                  color: root.foreground
                  font.family: Style.font.resolvedFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: chosen
                  elide: Text.ElideRight
                }

                Text {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.bottom: parent.bottom
                  anchors.leftMargin: Style.space(9)
                  anchors.rightMargin: Style.space(9)
                  anchors.bottomMargin: Style.space(7)

                  text: model.description || model.id
                  color: root.muted
                  font.family: Style.font.resolvedFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }

              Rectangle {
                visible: chosen
                width: Style.space(6)
                height: Style.space(6)
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(8)
                color: root.foreground
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: themeCard.hovered = true
                onExited: themeCard.hovered = false
                onClicked: root.selectTheme(index)
              }
            }
          }
        }
        PanelSeparator {
          Layout.fillWidth: true
          foreground: root.border
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(24)

          Text {
            text: "CURATED WALLPAPERS"
            color: root.muted
            font.family: Style.font.resolvedFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
          }

          Item { Layout.fillWidth: true }

          Text {
            text: wallpaperModel.count > 0
              ? wallpaperModel.count + " WALLPAPERS"
              : "NO WALLPAPERS"

            color: root.muted
            font.family: Style.font.resolvedFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: root.wallpaperSectionHeight

          ListView {
            id: wallpaperList

            anchors.fill: parent

            orientation: ListView.Horizontal
            spacing: Style.space(10)
            clip: true
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            snapMode: ListView.SnapToItem
            currentIndex: root.wallpaperIndex

            onCurrentIndexChanged: {
              if (currentIndex >= 0 && currentIndex !== root.wallpaperIndex)
                root.selectWallpaper(currentIndex)
            }

            model: wallpaperModel

            delegate: Item {
              id: wallpaperCard

              width: root.wallpaperCardWidth
              height: root.wallpaperCardHeight

              property bool chosen: model.path === root.selectedWallpaper
              property bool hovered: false

              scale: hovered ? 1.012 : 1

              Behavior on scale {
                NumberAnimation {
                  duration: 100
                  easing.type: Easing.OutCubic
                }
              }

              Rectangle {
                anchors.fill: parent

                color: chosen
                  ? Util.alpha(root.foreground, 0.10)
                  : Util.alpha(root.foreground, 0.025)

                border.width: chosen ? 2 : 1
                border.color: chosen
                  ? root.foreground
                  : Util.alpha(root.foreground, hovered ? 0.34 : 0.13)
              }

              Image {
                anchors.fill: parent
                anchors.margins: 2

                source: model.url
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
              }

              Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                height: Style.space(34)
                color: Util.alpha(root.background, 0.84)

                Text {
                  anchors.fill: parent
                  anchors.leftMargin: Style.space(9)
                  anchors.rightMargin: Style.space(9)

                  text: model.name
                  color: root.foreground
                  font.family: Style.font.resolvedFamily
                  font.pixelSize: Style.font.caption
                  font.bold: chosen
                  verticalAlignment: Text.AlignVCenter
                  elide: Text.ElideMiddle
                }
              }

              Rectangle {
                visible: chosen
                width: Style.space(7)
                height: Style.space(7)
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(9)
                color: root.foreground
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: wallpaperCard.hovered = true
                onExited: wallpaperCard.hovered = false
                onClicked: root.selectWallpaper(index)
              }
            }
          }

          Text {
            anchors.centerIn: parent
            visible: wallpaperModel.count === 0

            text: "No curated wallpapers for this theme"
            color: root.muted
            font.family: Style.font.resolvedFamily
            font.pixelSize: Style.font.body
          }
        }
        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(44)
          spacing: Style.space(12)

          Text {
            Layout.fillWidth: true

            text: root.selectedWallpaper
              ? root.selectedWallpaper.split("/").pop()
              : "Theme only"

            color: root.muted
            font.family: Style.font.resolvedFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideMiddle
          }

          Text {
            text: "← → themes   ↑ ↓ wallpapers"
            color: root.muted
            font.family: Style.font.resolvedFamily
            font.pixelSize: Style.font.caption
          }

          Rectangle {
            Layout.preferredWidth: Style.space(122)
            Layout.preferredHeight: Style.space(36)

            color: root.foreground
            border.width: 1
            border.color: root.foreground

            Text {
              anchors.fill: parent

              text: applyProc.running ? "APPLYING…" : "APPLY"

              color: root.background
              font.family: Style.font.resolvedFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true

              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
              anchors.fill: parent
              enabled: !!root.selectedTheme && !applyProc.running
              onClicked: root.applySelection()
            }
          }
        }
      }
    }
  }
}
