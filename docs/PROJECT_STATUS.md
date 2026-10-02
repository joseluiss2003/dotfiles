# SwayP 1.5 project status

This document keeps the SwayP project state separate from future ideas and known technical debt.

## Completed

- Centralized SwayP configuration under the single `swayp/` Stow package.
- Sway-native desktop configuration.
- Centralized Quickshell shell, core, UI, services and first-party plugin registry.
- Semantic theme system with generated application configuration.
- Curated theme collection:
  - Black Metal
  - Catppuccin
  - Catppuccin Latte
  - Flexoki Light
  - Gruvbox
  - Kanagawa
  - Osaka Jade
  - Rosé Pine Dawn
- Theme and wallpaper selector.
- Bar, workspace, clock, tray and system widgets.
- Audio, Bluetooth, network, power and microphone controls.
- Notifications and notification center.
- OSD and clipboard functionality.
- Quickshell lockscreen integration.
- Maple Mono NF typography for Sway and Quickshell, installed through the Arch AUR.
- Reproducible Arch installer with GNU Stow.
- Optional utility installation through `./install.sh --extras`.
- Legacy Stow layout migration in the installer.
- Shared Quickshell typography and semantic color primitives.
- Media-player wheel volume adjustment.
- Centralized Quickshell typography, spacing and UI scaling through `qs.core.Style`.
- Configurable Quickshell scale exposed through the Display panel and persisted in `~/.config/swayp/shell.toml`.
- TUI-inspired panels with compact selection markers and unified headers.
- CLI-inspired desktop clock widget.
- CLI-inspired weather widget with a large seven-segment temperature display.
- Matrix-style desktop widget.
- Desktop widget geometry tied to centralized `Style` scaling.
- Shared Open-Meteo weather service.
- Lightweight 960×540 theme previews with lazy loading of visible previews.

## Active development

- `revamping/swayp-1.5` is the current visual-polishing line.
- Continue refining the TUI/CLI visual language where it adds clarity without turning the whole desktop into a terminal imitation.
- The top bar is currently considered visually settled; its icon-based desktop language is intentional.

## Technical debt

- Some Quickshell code paths still produce Qt deprecation warnings in development logs. These are cleanup work, not part of the core SwayP 1.0 architecture.
- The visual catalogue can continue to receive small consistency improvements without introducing a second theme system.

## Known issues

- If Quickshell is already running before a manually installed font is registered with Fontconfig, the existing process may need to be restarted before it resolves the new family. A fresh SwayP installation installs Maple Mono NF before the normal shell session starts.
- The installer requires an existing `yay` or `paru` helper for Maple Mono NF; `--extras` also uses it for Obsidian.

## Prototypes / experiments

- Matrix remains a lightweight static desktop visualisation rather than a full terminal `cmatrix` integration.
- TUI/CLI experiments should stay inside the existing plugin/UI architecture.

## Future ideas

These are deliberately not part of the SwayP 1.0 completion criteria:

- Further animation and transition polish.
- Additional carefully curated themes.
- More visual documentation and screenshots.
- Small usability improvements discovered through continued daily use.

## Release boundary

SwayP 1.0 is considered the point where the project stopped being only a collection of personal dotfiles and became a complete, reproducible Sway desktop shell.

Future work should preserve the central architecture and avoid adding parallel implementations for existing responsibilities.
