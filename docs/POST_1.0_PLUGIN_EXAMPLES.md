# Post-1.0 plugin reference: System Inspector

Status: **archived prototype — not part of the active SwayP installation**.

This document records the first larger first-party Quickshell plugin built after the SwayP 1.0 architecture was established. It is kept as a reference for future post-1.0 plugin work, not as a feature to ship or enable.

## What it demonstrated

The System Inspector was a fullscreen diagnostic panel for:

- CPU and load
- memory usage
- optional NVIDIA telemetry
- Sway window/workspace counts
- focused workspace and monitor state
- displays and refresh rates
- Sway and Quickshell versions
- kernel version
- Night Light service state
- enabled SwayP plugins
- clipboard export of diagnostics

It used the central SwayP architecture rather than introducing a parallel framework.

## Architectural patterns worth reusing

### Central plugin infrastructure

The plugin was registered as:

```text
swayp.inspector
```

and exposed a normal `Panel.qml` entry point through `manifest.json`.

It consumed the existing plugin registry through the shell object instead of maintaining a separate plugin inventory.

### Central theme system

The panel deliberately used semantic SwayP roles:

```qml
Color.menu.background
Color.menu.text
Color.menu.border
Color.menu.scrim
Color.surfaceAlt
Color.accent
Color.success
Color.warning
Color.info
Color.divider
```

and shared geometry/typography:

```qml
Style.space(...)
Style.spacing.*
Style.font.*
BorderSurface
PanelActionButton
```

No theme-specific hex palette was embedded in the plugin.

### Sway-native runtime data

The prototype used:

- `swaymsg -t get_outputs -r`
- `swaymsg -t get_tree -r`
- `Quickshell.I3`
- `/proc/stat`
- `/proc/meminfo`
- `/proc/loadavg`
- `/proc/uptime`
- optional `nvidia-smi`

It contained no Hyprland dependency.

### UI structure

The final prototype established a useful fullscreen diagnostic composition:

```text
SYSTEM INSPECTOR
────────────────────────────────────────

[ CPU ] [ MEMORY ] [ GPU ]
[ SWAY ] [ UPTIME ] [ NIGHT LIGHT ]

DISPLAYS                 RUNTIME
DP-2                     Sway ...
DP-1                     Quickshell ...
                         Focused ...
                         Workspace ...

PLUGINS
[ Audio ] [ Clipboard ] [ Network ] ...

────────────────────────────────────────
```

The outer surface used the normal SwayP menu surface language. Internal metric/plugin borders were later reduced to the semantic divider color so that themes such as Gruvbox did not acquire excessive cyan/outline contrast.

## Lessons learned

1. **Do not create a new visual language for diagnostic tools.** Reuse the shell's existing surface, border, spacing and typography systems.
2. **Use semantic colors all the way down.** Passing a fallback color into a generic border resolver is not enough when that resolver intentionally prioritizes theme tokens. For intentionally subdued borders, use an explicit divider border spec.
3. **Separate compositor state from UI parsing.** `Model.js` kept /proc, Sway IPC and GPU parsing outside the QML layout.
4. **Use Quickshell.I3 for focused monitor/workspace state where possible.** The Sway tree remains useful for focused client/window information.
5. **Make long diagnostic strings responsive.** Runtime and GPU strings need elision/width constraints.
6. **A useful prototype does not automatically deserve to become a product feature.** The inspector proved that the plugin architecture can support a substantial first-party panel; it is intentionally archived because it is not needed in the SwayP 1.0 product surface.

## Reference implementation

The implementation was developed directly on `feature/classic-themes` and is preserved in Git history.

Relevant final development commits:

- `0d790859` — session menu alignment work immediately before the inspector effort
- inspector implementation and hardening commits around the System Inspector prototype
- `d6dcae7` — `use muted divider borders in inspector`

The final active prototype consisted of:

```text
swayp/.config/quickshell/plugins/inspector/
├── manifest.json
├── Model.js
└── Panel.qml
```

The active files are intentionally removed after this documentation entry. Git history remains the source archive for the complete implementation.

## Future use

When designing a new post-1.0 first-party plugin, use this prototype as an architectural reference, not as a component to copy blindly.

Compare the new feature against:

- the central plugin registry
- `qs.core.Color`
- `qs.core.Style`
- `Border.qml`
- `BorderSurface.qml`
- `Button.qml`
- existing service injection patterns
- the reproducible installer

The goal is to preserve the **centralized SwayP architecture** while avoiding accumulation of experimental UI in the production plugin tree.
