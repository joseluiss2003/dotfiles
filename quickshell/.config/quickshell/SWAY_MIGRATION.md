# Omarchy Quattro → Sway migration

This tree keeps the Omarchy Quattro shell architecture while routing
compositor-specific state through `qs.core.Sway`.

## Phase 1

- Added `Commons/Sway.qml` as the compositor facade.
- Routed the bar's focused output through `Sway.focusedMonitor`.
- Routed workspace state and dispatch through `Sway`.
- Removed obsolete Hyprland polling code from `Commons/Style.qml`.
- Kept visual defaults unchanged (`cornerRadius=0`, `gapsOut=5`) unless
  overridden by shell style configuration.

## Remaining runtime ports

1. notification app focusing
2. lock stranded-session / DPMS handling
3. nightlight backend
4. idle compositor event integration

The original uploaded dotfiles archive remains untouched; this is a derived
working tree for the migration.
