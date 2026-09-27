# SwayP architecture

SwayP is the Sway-native evolution of the original Quickshell configuration.

## Current architecture

- `core/Sway.qml` contains compositor-specific access.
- `core/Style.qml` owns shared typography, spacing and sizing tokens.
- `core/Color.qml` consumes the Aether-generated palette.
- `ui/` contains reusable shell surfaces and controls.
- `services/PluginRegistry.qml` discovers first-party plugins.
- `plugins/` contains the bar, panels, services and overlays.
- `shell.qml` owns lifecycle, IPC, configuration and plugin orchestration.

## Sway integration

Workspace, focused-output and compositor actions are routed through Sway IPC rather than Hyprland-specific polling.

Idle locking is coordinated with Sway/SwayIdle. The lock surface itself uses Quickshell's native Wayland session-lock support.

## Theme integration

Aether generates the shared palette consumed by Sway, Kitty, Fuzzel, Mako, Starship and Quickshell.

## Migration status

The runtime namespace, configuration paths and first-party plugin identifiers are SwayP-owned. Remaining external commands are treated as explicit compatibility dependencies and are not part of the SwayP core contract.
