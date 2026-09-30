pragma Singleton
import QtQuick

// Central Nerd Font icon vocabulary for SwayP.
//
// Keep glyphs here instead of scattering private Unicode literals across
// plugins. Components should consume semantic names (Icons.network,
// Icons.volume, Icons.battery(...), ...) so the icon language can evolve
// without touching plugin behavior.
//
// The glyphs target the patched Nerd Font used by SwayP. They are plain
// Unicode strings: no icon package or runtime dependency is introduced.
QtObject {
  readonly property string menu: "󰍜"
  readonly property string workspaces: "󰨞"
  readonly property string window: "󰖲"
  readonly property string clock: "󰥔"
  readonly property string tray: "󰇘"

  readonly property string network: "󰤨"
  readonly property string wifi: "󰤨"
  readonly property string ethernet: "󰈀"
  readonly property string bluetooth: "󰂯"
  readonly property string audio: "󰕾"
  readonly property string volumeMuted: ""
  readonly property string volumeLow: ""
  readonly property string volumeMedium: ""
  readonly property string volumeHigh: ""
  readonly property string headphones: "󰋋"
  readonly property string microphone: "󰍬"
  readonly property string microphoneMuted: "󰍭"
  readonly property string notifications: "󰂚"
  readonly property string notificationOff: "󰂛"
  readonly property string monitor: "󰍹"
  readonly property string nightLight: "󰖔"
  readonly property string power: "󰐥"
  readonly property string lock: "󰌾"
  readonly property string logout: "󰍃"
  readonly property string reboot: "󰜉"
  readonly property string shutdown: "󰐥"

  readonly property string search: "󰍉"
  readonly property string settings: "󰒓"
  readonly property string clipboard: "󰅍"
  readonly property string speed: "󰓅"
  readonly property string theme: "󰏘"
  readonly property string wallpaper: "󰸉"

  readonly property string check: "󰄬"
  readonly property string close: "󰅖"
  readonly property string plus: "󰐕"
  readonly property string minus: "󰍴"
  readonly property string chevronRight: "󰅂"
  readonly property string chevronLeft: "󰅁"
  readonly property string chevronUp: "󰅃"
  readonly property string chevronDown: "󰅀"
  readonly property string arrowRight: "󰁔"
  readonly property string arrowLeft: "󰁍"
  readonly property string refresh: "󰑐"
  readonly property string info: "󰋼"
  readonly property string warning: "󰀪"
  readonly property string error: "󰅚"

  readonly property string profilePowerSaver: "󰌪"
  readonly property string profileBalanced: "󰊚"
  readonly property string profilePerformance: "󰓅"
  readonly property string profileFallback: "󰂄"

  readonly property var battery: [
    "󰁺", "󰁻", "󰁼", "󰁽", "󰁾",
    "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"
  ]

  readonly property var batteryCharging: [
    "󰢜", "󰂆", "󰂇", "󰂈", "󰢝",
    "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"
  ]
}
