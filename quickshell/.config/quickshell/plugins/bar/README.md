# SwayP bar

The built-in status bar is the `swayp.bar` first-party plugin. It renders the
bar on each Sway output and loads widgets through the shared plugin registry.

## Layout

The default layout is defined by the SwayP shell configuration:

`~/.config/swayp/shell.json`

The shell also provides a built-in default layout when no user configuration
exists.

A layout entry identifies a widget by its SwayP plugin ID, for example:

```json
{
  "left": [
    { "id": "swayp.workspaces" }
  ],
  "center": [
    { "id": "swayp.clock", "format": "HH:mm" }
  ],
  "right": [
    { "id": "swayp.media" },
    { "id": "swayp.audio" }
  ]
}
```

## Built-in widgets

Common widgets include:

- `swayp.workspaces` — Sway workspace state.
- `swayp.active-window` — focused application.
- `swayp.clock` — date and time.
- `swayp.media` — MPRIS now-playing information and controls.
- `swayp.audio` — PipeWire output controls.
- `swayp.microphone` — microphone state and mute.
- `swayp.network` — network status.
- `swayp.bluetooth` — Bluetooth controls.
- `swayp.monitor` — display brightness and text-size controls.
- `swayp.power` — battery and power controls.
- `swayp.tray` — system tray.
- `swayp.indicators` — compact state indicators.
- `swayp.menu` — SwayP session/menu launcher.

## Plugin model

Widgets declare their identity in a nearby `manifest.json`. The bar resolves
the manifest through the shell's first-party plugin registry and injects the
bar API, settings and module identity into the widget.

Custom command entries can also be supplied through the shell configuration
without adding a QML plugin.

## Visual behaviour

The bar follows the shared SwayP theme and style tokens from `qs.core`.
Matugen-generated colors are consumed through `core/Color.qml`, while
geometry and typography are centralized in `core/Style.qml`.

The implementation is intentionally multi-monitor aware and keeps panel
anchors tied to the output that owns the bar instance.
