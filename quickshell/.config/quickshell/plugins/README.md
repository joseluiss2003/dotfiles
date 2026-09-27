# SwayP first-party plugins

First-party plugins are shipped with SwayP and discovered by the shell at startup. Each plugin declares its contract in a `manifest.json`.

## Plugin catalogue

| Plugin | ID | Entry point |
|---|---|---|
| Background | `swayp.background` | `background/Background.qml` |
| Bar | `swayp.bar` | `bar/Bar.qml` |
| Active window | `swayp.active-window` | `active-window/BarWidget.qml` |
| Indicators | `swayp.indicators` | `indicators/BarWidget.qml` |
| Keyboard layout | `swayp.keyboard-layout` | `keyboard-layout/BarWidget.qml` |
| Microphone | `swayp.microphone` | `microphone/BarWidget.qml` |
| Spacer | `swayp.spacer` | `spacer/BarWidget.qml` |
| System update | `swayp.system-update` | `system-update/BarWidget.qml` |
| Tray | `swayp.tray` | `tray/BarWidget.qml` |
| Workspaces | `swayp.workspaces` | `workspaces/BarWidget.qml` |
| Clipboard | `swayp.clipboard` | `clipboard/Panel.qml` |
| Dev gallery | `swayp.dev-gallery` | `dev-gallery/GalleryPanel.qml` |
| Emojis | `swayp.emojis` | `emojis/Emojis.qml` |
| Image picker | `swayp.image-picker` | `image-picker/ImagePicker.qml` |
| Lock | `swayp.lock` | `lock/Service.qml` |
| Menu | `swayp.menu` | `menu/Menu.qml` |
| Notification center | `swayp.notification-center` | `notifications-center/Panel.qml` |
| Notifications | `swayp.notifications` | `notifications/Service.qml` |
| OSD | `swayp.osd` | `osd/Osd.qml` |
| Audio | `swayp.audio` | `audio/Panel.qml` |
| Bluetooth | `swayp.bluetooth` | `bluetooth/Panel.qml` |
| Clock | `swayp.clock` | `clock/BarWidget.qml` |
| Monitor | `swayp.monitor` | `monitor/Panel.qml` |
| Network | `swayp.network` | `network/Panel.qml` |
| Power | `swayp.power` | `power/Panel.qml` |
| Speed test | `swayp.speedtest` | `speedtest/Panel.qml` |
| Wi-Fi QR | `swayp.wifiqr` | `wifiqr/Panel.qml` |
| Polkit | `swayp.polkit` | `polkit/PolkitAgent.qml` |
| Battery | `swayp.battery` | `services/battery/Service.qml` |
| Idle | `swayp.idle` | `services/idle/Service.qml` |
| Media | `swayp.media` | `services/media/Service.qml` + `BarWidget.qml` |
| Night light | `swayp.nightlight` | `services/nightlight/Service.qml` |

## Configuration

The bar reads its configuration from `~/.config/swayp/shell.json`. The shell ships a SwayP default layout and user configuration can override it.

Third-party or user-specific extensions should live outside the repository under the user's SwayP configuration directory.

## Ownership

SwayP owns the plugin IDs, runtime namespaces and configuration paths. External commands used by a small number of optional features are compatibility dependencies and are deliberately kept isolated from the core plugin architecture.
