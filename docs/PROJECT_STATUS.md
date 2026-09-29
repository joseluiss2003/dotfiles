# SwayP 1.0 project status

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
- Geist v1.7.2 and Geist Mono installation with SHA-256 verification.
- Reproducible Arch installer with GNU Stow.
- Optional utility installation through `./install.sh --extras`.
- Legacy Stow layout migration in the installer.
- Shared Quickshell typography and semantic color primitives.
- Media-player wheel volume adjustment.

## Technical debt

- Some Quickshell code paths still produce Qt deprecation warnings in development logs. These are cleanup work, not part of the core SwayP 1.0 architecture.
- The visual catalogue can continue to receive small consistency improvements without introducing a second theme system.

## Known issues

- If Quickshell is already running before a manually installed font is registered with Fontconfig, the existing process may need to be restarted before it resolves the new family. A fresh SwayP installation installs Geist before starting the normal shell session.
- Optional Obsidian installation requires an existing `yay` or `paru` helper when `--extras` is used.

## Future ideas

These are deliberately not part of the SwayP 1.0 completion criteria:

- Further animation and transition polish.
- Additional carefully curated themes.
- More visual documentation and screenshots.
- Small usability improvements discovered through continued daily use.

## Release boundary

SwayP 1.0 is considered the point where the project stopped being only a collection of personal dotfiles and became a complete, reproducible Sway desktop shell.

Future work should preserve the central architecture and avoid adding parallel implementations for existing responsibilities.
