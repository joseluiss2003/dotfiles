# SwayP 1.5 architecture

This is the short reference for how the SwayP 1.0 shell fits together. Update it when the architecture changes.

SwayP began as a small Sway customization project and evolved into a complete desktop shell. The architecture intentionally keeps SwayP independent while taking Omarchy/Quattro as a visual and architectural reference.

## Repository package

All SwayP-owned desktop configuration is centralized in the single `swayp/` Stow package:

~~~text
swayp/
├── .config/
│   ├── fuzzel/
│   ├── kitty/
│   ├── quickshell/
│   ├── sway/
│   └── swayp/
├── .local/bin/       # user-level SwayP utilities
└── .zshrc            # shell configuration
~~~

This keeps the repository structure aligned with the installed home-directory layout while leaving `install.sh` and project documentation at the repository root.

## Layers

### Sway
Sway is the compositor and window-management layer. Its generated theme colors live in ~/.config/swayp/generated/sway-colors.conf.

SwayP must remain Sway-native. Do not introduce Hyprland-specific APIs, commands or configuration assumptions.

### Quickshell
~~~text
swayp/.config/quickshell/
├── shell.qml      # shell entry point and orchestration
├── core/          # shared state, colors, style and helpers
├── ui/            # reusable visual components
├── services/      # registries and shared service infrastructure
└── plugins/       # first-party widgets, panels, services and overlays
~~~

shell.qml owns shell lifecycle, configuration and plugin orchestration.

### Generated configuration
The script `swayp/.local/bin/swayp-theme-set` turns one theme into runtime configuration:

~~~text
~/.config/swayp/generated/
├── colors.toml
├── palette.json
├── sway-colors.conf
├── kitty-colors.conf
├── starship.toml
├── fastfetch.jsonc
└── fuzzel-colors.ini
~~~

These files are runtime output. Do not edit them manually.

## Theme authority
Theme source lives in the repository under swayp/.config/swayp/themes/<theme>/:

~~~text
├── colors.toml
└── theme.toml
~~~

Wallpapers are shipped under `swayp/.config/swayp/wallpapers/<theme>/` and become `~/.config/swayp/wallpapers/<theme>/` after Stow. Runtime/user-added wallpapers may also live directly under `~/.config/swayp/wallpapers/<theme>/`.

colors.toml is the canonical palette. Quickshell reads generated palette.json through core/Color.qml.

**Rule:** components consume semantic roles; they do not invent their own theme system.

For example, plugins should use Color.accent, Color.background, Color.muted and Style.space(...) instead of embedding Catppuccin, Dracula or Solarized hex values.

## Quickshell plugin model
The plugin registry scans first-party plugins under swayp/.config/quickshell/plugins/ and user plugins under ~/.config/swayp/plugins/.

Every plugin declares its contract in manifest.json.

Current plugin kinds are:
- bar
- bar-widget
- panel
- service
- menu
- overlay

A plugin may declare multiple kinds and entry points.

The registry validates manifests and rejects unsafe absolute or parent-traversing entry points.

## Configuration
The current shell configuration is `~/.config/swayp/shell.toml`. Repository defaults are supplied under `swayp/.config/swayp/`.

The Display panel exposes a Quickshell scale setting stored under `[quickshell]`. It is separate from Sway output scaling.

Bar widgets are identified by plugin ID:

~~~json
{
  "left": [{ "id": "swayp.workspaces" }],
  "center": [{ "id": "swayp.clock" }],
  "right": [{ "id": "swayp.audio" }]
}
~~~

## Desktop widgets

The current desktop layer includes:

- a large seven-segment CLI-style clock;
- a large seven-segment CLI-style weather temperature display backed by a shared weather service;
- a Matrix-style decorative widget.

All three use centralized `Style` geometry scaling so their proportions remain coherent when Quickshell scale changes.

The current top bar remains icon-oriented and intentionally conventional; the stronger TUI/CLI language is concentrated in panels and desktop widgets.

## Runtime state
Persistent runtime state lives under ~/.local/state/swayp/. Examples include the active theme, palette and notification history.

Regeneratable output belongs in the appropriate XDG runtime/cache locations, not in the repository.

## External reference

Omarchy and its Quattro direction are an explicit architectural and visual reference for SwayP. SwayP does not treat Omarchy as a runtime dependency; its shell, plugin registry, theme generator and configuration remain SwayP-owned.

## Design rules
- One source of truth per concern.
- Shared visual primitives belong in core/ and ui/.
- Feature-specific logic belongs in its plugin directory.
- Theme-specific data belongs in themes, not QML.
- Generated files are never the source of truth.
- Prefer small composable APIs over direct plugin coupling.
- Do not add a daemon merely to pass data that can be generated or shared directly.
- Do not introduce Hyprland-specific dependencies into the Sway line.
- Do not create parallel plugin, IPC, color or style systems.