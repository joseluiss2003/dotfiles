# SwayP architecture

This is the short reference for how the project fits together. Update it when the architecture changes.

## Layers

### Sway
Sway is the compositor and window-management layer. Its generated theme colors live in ~/.config/swayp/generated/sway-colors.conf.

SwayP must remain Sway-native. Do not introduce Hyprland-specific APIs, commands or configuration assumptions.

### Quickshell
~~~text
quickshell/.config/quickshell/
├── shell.qml      # shell entry point and orchestration
├── core/          # shared state, colors, style and helpers
├── ui/            # reusable visual components
├── services/      # registries and shared service infrastructure
└── plugins/       # first-party widgets, panels, services and overlays
~~~

shell.qml owns shell lifecycle, configuration and plugin orchestration.

### Generated configuration
The script scripts/.local/bin/swayp-theme-set turns one theme into runtime configuration:

~~~text
~/.config/swayp/generated/
├── colors.toml
├── palette.json
├── sway-colors.conf
├── kitty-colors.conf
├── starship.toml
├── fastfetch.jsonc
├── mako-colors
└── fuzzel-colors.ini
~~~

These files are runtime output. Do not edit them manually.

## Theme authority
Theme source lives under ~/.config/swayp/themes/<theme>/:

~~~text
├── colors.toml
└── theme.toml
~~~

Wallpapers live under ~/.config/swayp/wallpapers/<theme>/.

colors.toml is the canonical palette. Quickshell reads generated palette.json through core/Color.qml.

**Rule:** components consume semantic roles; they do not invent their own theme system.

For example, plugins should use Color.accent, Color.background, Color.muted and Style.space(...) instead of embedding Catppuccin, Dracula or Solarized hex values.

## Quickshell plugin model
The plugin registry scans first-party plugins under quickshell/.config/quickshell/plugins/ and user plugins under ~/.config/swayp/plugins/.

Every plugin declares its contract in manifest.json.

Current plugin kinds are:
- bar
- bar-widget
- panel
- service
- menu

A plugin may declare multiple kinds and entry points.

The registry validates manifests and rejects unsafe absolute or parent-traversing entry points.

## Configuration
The shell configuration is ~/.config/swayp/shell.json. The repository supplies defaults and the shell falls back to them when user configuration is invalid or unavailable.

Bar widgets are identified by plugin ID:

~~~json
{
  "left": [{ "id": "swayp.workspaces" }],
  "center": [{ "id": "swayp.clock" }],
  "right": [{ "id": "swayp.audio" }]
}
~~~

## Runtime state
Persistent runtime state lives under ~/.local/state/swayp/. Examples include the active theme, palette and notification history.

Regeneratable output belongs in the appropriate XDG runtime/cache locations, not in the repository.

## Design rules
- One source of truth per concern.
- Shared visual primitives belong in core/ and ui/.
- Feature-specific logic belongs in its plugin directory.
- Theme-specific data belongs in themes, not QML.
- Generated files are never the source of truth.
- Prefer small composable APIs over direct plugin coupling.
- Do not add a daemon merely to pass data that can be generated or shared directly.