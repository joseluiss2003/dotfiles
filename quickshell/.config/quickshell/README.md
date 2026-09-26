# SwayP Quickshell

Quickshell is the UI layer of SwayP. It hosts the bar, panels, popups, widgets and shared desktop services in a single shell process.

## Structure

- `shell.qml` — shell entry point, plugin lifecycle and IPC.
- `core/` — shared state, styling, compositor helpers and utilities.
- `ui/` — reusable visual and interaction components.
- `services/` — registries and shared service infrastructure.
- `plugins/` — first-party bar widgets, panels and services.
- `generated/` — Matugen-generated theme files.

## Configuration

The shell keeps user configuration under `~/.config/swayp/`.

Matugen owns the generated theme layer. Quickshell consumes the generated theme and the SwayP shell configuration without depending on an Omarchy installation.

## Runtime model

SwayP runs one long-lived Quickshell process. Plugins are registered through their `manifest.json` files and loaded according to their kind and lifecycle policy.

The bar, panels and services communicate through the shell's internal plugin registry and IPC instead of launching a second shell process.

## Design goals

- Native Sway integration.
- Matugen as the central theme source.
- Zero-radius, compact UI where configured.
- Multi-monitor aware panels and notifications.
- Clear separation between core, UI, services and plugins.
- SwayP-owned paths and runtime identifiers.
