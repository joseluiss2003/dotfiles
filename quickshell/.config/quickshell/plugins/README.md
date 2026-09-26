# SwayP first-party plugins

First-party plugins are shipped with SwayP and discovered by the shell at startup. Each plugin declares its contract in a `manifest.json`.

## Plugin catalogue

| Plugin | ID | Entry point |
|---|---|---|
| Background | `swayp.background` | `background/Background.qml` |
| Bar | `swayp.bar` | `bar/Bar.qml` |
| Active window | `swayp.active-window` | `bar/widgets/ActiveWindow.qml` |
| Indicators | `swayp.indicators` | `bar/widgets/Indicators.qml` |
| Keyboard layout | `swayp.keyboard-layout` | `bar/widgets/KeyboardLayout.qml` |
| Microphone | `swayp.microphone` | `bar/widgets/Microphone.qml` |
| Spacer | `swayp.spacer` | `bar/widgets/Spacer.qml` |
| System update | `swayp.system-update` | `bar/widgets/SystemUpdate.qml` |
| Tray | `swayp.tray` | `bar/widgets/Tray.qml` |
| Workspaces | `swayp.workspaces` | `bar/widgets/Workspaces.qml` |
| Clipboard | `swayp.clipboard` | `clipboard/Clipboard.qml` |
| Dev gallery | `swayp.dev-gallery` | `dev-gallery/GalleryPanel.qml` |
| Emojis | `swayp.emojis` | `emojis/Emojis.qml` |
| Image picker | `swayp.image-picker` | `image-picker/ImagePicker.qml` |
| Lock | `swayp.lock` | `lock/Service.qml` |
| Menu | `swayp.menu` | `menu/Menu.qml` |
| Notification center | `swayp.notification-center` | `notifications-center/Panel.qml` |
| Notifications | `swayp.notifications` | `notifications/Service.qml` |
| OSD | `swayp.osd` | `osd/Osd.qml` |
| Audio | `swayp.audio` | `panels/audio/Panel.qml` |
| Bluetooth | `swayp.bluetooth` | `panels/bluetooth/Panel.qml` |
| Clock | `swayp.clock` | `panels/clock/BarWidget.qml` |
| Monitor | `swayp.monitor` | `panels/monitor/Panel.qml` |
| Network | `swayp.network` | `panels/network/Panel.qml` |
| Power | `swayp.power` | `panels/power/Panel.qml` |
| Speed test | `swayp.speedtest` | `panels/speedtest/Panel.qml` |
| Wi-Fi QR | `swayp.wifiqr` | `panels/wifiqr/Panel.qml` |
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
