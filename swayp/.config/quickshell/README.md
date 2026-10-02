# SwayP Quickshell

Quickshell is the UI and service layer of SwayP. It hosts the bar, panels, desktop widgets, overlays and shared desktop services in one shell process.

## Structure
~~~text
quickshell/.config/quickshell/
├── shell.qml      # shell entry point and orchestration
├── core/          # shared state, colors, style and helpers
├── ui/            # reusable visual components
├── services/      # registries and shared service infrastructure
└── plugins/       # first-party widgets, panels, services and overlays
~~~

## Style and scaling

`qs.core.Color` provides semantic theme roles and `qs.core.Style` provides typography, spacing and Quickshell scaling. The Display panel exposes the Quickshell scale and persists it under `[quickshell]` in `~/.config/swayp/shell.toml`.

Desktop widget geometry must use centralized `Style` scaling so clock, weather and Matrix remain proportional.

## Theme system
SwayP does not use a runtime theme daemon.

The source of truth is ~/.config/swayp/themes/<theme>/ with colors.toml and theme.toml.

swayp-theme-set generates application configuration and writes the active semantic palette to runtime state. Quickshell consumes that palette through core/Color.qml.

See:
- [Project architecture](../../../docs/ARCHITECTURE.md)
- [Plugin guide](../../../docs/PLUGINS.md)
- [Theme guide](../../../docs/THEMES.md)

## Runtime model
SwayP runs one long-lived Quickshell process.

First-party plugins are discovered from the bundled plugins/ directory. User plugins can live under ~/.config/swayp/plugins/.

Plugins declare their contract in manifest.json and are loaded according to their declared kind and lifecycle.

## Design rules
- Keep the shell Sway-native.
- Reuse qs.core.Color and qs.core.Style.
- Keep plugin-specific logic inside the plugin directory.
- Inject shared services instead of instantiating duplicates.
- Do not introduce a second theme system.
- Keep UI compact, square, composable and multi-monitor aware.
- Use the existing TUI/CLI visual language for panels and widgets without forcing the bar into a terminal-only aesthetic.