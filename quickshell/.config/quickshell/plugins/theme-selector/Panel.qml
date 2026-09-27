import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui

Item {
  id: root

  readonly property string moduleName: "swayp.theme-selector"
  property bool opened: false
  property Item anchorItem: null
  property QtObject bar: null
  property QtObject shell: null
  property string home: Quickshell.env("HOME")
  property string themesDir: home + "/.config/swayp/themes"
  property string wallpapersRoot: home + "/.config/swayp/wallpapers"
  property string currentThemePath: home + "/.local/state/swayp/current/theme.name"
  property string selectedTheme: ""
  property string selectedWallpaper: ""
  property int themeIndex: 0
  property int wallpaperIndex: 0

  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property color muted: Color.muted
  property color selection: Color.menu.selectedBackground

  function open(payloadJson) {
    root.opened = true
    root.selectedWallpaper = ""
    root.loadCurrentTheme()
    root.loadThemes()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
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
      root.wallpaperIndex = Math.max(0, Math.min(root.wallpaperIndex, wallpaperModel.count - 1))
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
    root.loadWallpapers()
  }

  function selectWallpaper(index) {
    if (index < 0 || index >= wallpaperModel.count) return
    root.wallpaperIndex = index
    root.selectedWallpaper = wallpaperModel.get(index).path
  }

  function applySelection() {
    if (!root.selectedTheme) return

    var wallpaper = root.selectedWallpaper
    applyProc.running = false
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
      var value = String(text || "").trim()
      if (value.length > 0) root.selectedTheme = value
    }
  }

  Process {
    id: themesProc
    command: [
      "bash", "-c",
      "set -eu; " +
      "for dir in \"$1\"/*; do " +
      "  [ -d \"$dir\" ] || continue; " +
      "  id=$(basename \"$dir\"); " +
      "  name=$(grep -m1 '^name[[:space:]]*=' \"$dir/theme.toml\" 2>/dev/null | cut -d= -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^[\\x22]//; s/[\\x22]$//'); " +
      "  [ -n \"$name\" ] || name=\"$id\"; " +
      "  desc=$(grep -m1 '^description[[:space:]]*=' \"$dir/theme.toml\" 2>/dev/null | cut -d= -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^[\\x22]//; s/[\\x22]$//'); " +
      "  preview=$(find \"$HOME/.config/swayp/wallpapers/$id\" -maxdepth 1 -type f " +
      "    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print | sort | head -n1); " +
      "  printf '%s\\t%s\\t%s\\t%s\\n' \"$id\" \"$name\" \"$desc\" \"$preview\"; " +
      "done | sort",
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
      "\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.svg' \) " +
      "-print | sort",
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
    command: ["notify-send", "SwayP", "Theme applied"]
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    bar: root.bar
    owner: root
    open: root.opened && !!root.anchorItem

    padding: 0
    drawBackground: false
    borderSpec: Border.surfaceSpec("theme-selector", "panel-wrapper", "transparent", 0)
    contentWidth: Math.min(Style.space(820), panel.availableCardWidth)
    contentHeight: Math.min(Style.space(610), panel.availableCardHeight)
    gap: Style.space(5)

    BorderSurface {
      id: card
      anchors.fill: parent
      color: root.background
      borderSpec: Border.surfaceSpec("theme-selector", "card", root.border, Math.max(1, Style.space(1)))
      radius: 0
      clip: true

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: root.opened

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.close()
            event.accepted = true
          } else if (event.key === Qt.Key_Left) {
            if (themeRow.activeFocus) root.selectTheme(Math.max(0, root.themeIndex - 1))
            event.accepted = true
          } else if (event.key === Qt.Key_Right) {
            if (themeRow.activeFocus) root.selectTheme(Math.min(themeModel.count - 1, root.themeIndex + 1))
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.selectWallpaper(Math.max(0, root.wallpaperIndex - 3))
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.selectWallpaper(Math.min(wallpaperModel.count - 1, root.wallpaperIndex + 3))
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.applySelection()
            event.accepted = true
          }
        }

        Component.onCompleted: Qt.callLater(function() { forceActiveFocus() })
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(16)
        spacing: Style.space(10)

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(48)

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(2)

            Text {
              text: "Appearance"
              color: root.foreground
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              text: root.selectedTheme
                    ? "Theme + curated wallpaper"
                    : "Choose a SwayP theme"
              color: root.muted
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.caption
              font.letterSpacing: 1.0
            }
          }

          Text {
            text: root.selectedTheme ? "󰏘 " + root.selectedTheme : "󰏘"
            color: Color.accent
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }
        }

        ListView {
          id: themeRow
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(142)
          orientation: ListView.Horizontal
          spacing: Style.space(8)
          clip: true
          model: themeModel

          delegate: Item {
            width: Style.space(150)
            height: Style.space(132)

            property bool chosen: index === root.themeIndex

            Rectangle {
              anchors.fill: parent
              color: chosen
                ? Util.alpha(Color.accent, 0.12)
                : Util.alpha(Color.foreground, 0.035)
              border.width: chosen ? 2 : 1
              border.color: chosen ? Color.accent : Util.alpha(Color.foreground, 0.18)
            }

            Image {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: 1
              height: Style.space(92)
              source: model.preview ? Util.fileUrl(model.preview) : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: true
            }

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: Style.space(40)
              color: chosen
                ? Util.alpha(Color.accent, 0.14)
                : Util.alpha(Color.background, 0.72)

              Text {
                anchors.fill: parent
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(8)
                text: model.name
                color: Color.foreground
                font.family: Style.font.menuFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: chosen
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onClicked: root.selectTheme(index)
            }
          }
        }

        PanelSeparator {
          Layout.fillWidth: true
          foreground: Color.outline
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(24)

          Text {
            text: "WALLPAPERS"
            color: root.muted
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.1
          }

          Item { Layout.fillWidth: true }

          Text {
            text: wallpaperModel.count > 0
              ? (root.wallpaperIndex + 1) + " / " + wallpaperModel.count
              : "NO WALLPAPERS"
            color: root.muted
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.caption
          }
        }

        GridView {
          id: wallpaperGrid
          Layout.fillWidth: true
          Layout.fillHeight: true
          cellWidth: Style.space(244)
          cellHeight: Style.space(128)
          clip: true
          model: wallpaperModel

          delegate: Item {
            width: Style.space(236)
            height: Style.space(120)

            property bool chosen: model.path === root.selectedWallpaper

            Rectangle {
              anchors.fill: parent
              color: chosen
                ? Util.alpha(Color.accent, 0.10)
                : Util.alpha(Color.foreground, 0.025)
              border.width: chosen ? 2 : 1
              border.color: chosen ? Color.accent : Util.alpha(Color.foreground, 0.14)
            }

            Image {
              anchors.fill: parent
              anchors.margins: 2
              source: model.url
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: true
            }

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: Style.space(26)
              color: Util.alpha(Color.background, 0.78)

              Text {
                anchors.fill: parent
                anchors.leftMargin: Style.space(8)
                anchors.rightMargin: Style.space(6)
                text: model.name
                color: Color.foreground
                font.family: Style.font.menuFamily
                font.pixelSize: Style.font.caption
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideMiddle
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onClicked: root.selectWallpaper(index)
            }
          }

          Text {
            anchors.centerIn: parent
            visible: wallpaperModel.count === 0
            text: "No curated wallpapers for this theme"
            color: root.muted
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.body
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(42)
          spacing: Style.space(8)

          Text {
            Layout.fillWidth: true
            text: root.selectedWallpaper
              ? root.selectedWallpaper.split("/").pop()
              : "Theme only"
            color: root.muted
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideMiddle
          }

          Rectangle {
            Layout.preferredWidth: Style.space(118)
            Layout.preferredHeight: Style.space(34)
            color: root.selectedTheme
              ? Color.accent
              : Util.alpha(Color.foreground, 0.08)
            border.width: 1
            border.color: root.selectedTheme ? Color.accent : Color.outline

            Text {
              anchors.fill: parent
              text: "APPLY"
              color: root.selectedTheme ? Color.background : Color.muted
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
              anchors.fill: parent
              enabled: !!root.selectedTheme
              onClicked: root.applySelection()
            }
          }
        }
      }
    }
  }
}
