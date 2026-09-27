# SwayP

Personal Sway desktop environment built around **Sway + Quickshell + Aether**.

SwayP is a native Sway setup with a modular Quickshell shell, dynamic Aether theming, and a small collection of user-level utilities. The project evolved from an Omarchy-inspired configuration while removing the desktop/runtime dependency itself.

## Stack

- **Sway** — compositor and window management
- **Quickshell** — bar, panels, widgets and desktop UI
- **Aether** — central dynamic theme and palette engine
- **Kitty** — terminal
- **Zsh + Starship** — shell and prompt
- **Fuzzel** — application launcher
- **Mako** — notifications
- **Fastfetch** — terminal system information

## Layout

```text
.
├── sway/       # Sway configuration
├── quickshell/ # Quickshell shell, services and UI
├── kitty/      # Kitty configuration
├── zsh/        # Zsh configuration
├── starship/   # Static Starship fallback
├── fuzzel/     # Application launcher
├── mako/       # Notifications
└── scripts/    # User-level utility commands
```

## Design goals

- Native Sway integration instead of compositor-specific assumptions.
- Aether as the single source for dynamic colors.
- Small, composable Quickshell components.
- Clear separation between core services, UI and plugins.
- No dependency on the Omarchy desktop itself.

## Installation

The repository is managed with GNU Stow. Aether generates the runtime palette consumed by SwayP.

```bash
git clone https://github.com/joseluiss2003/dotfiles.git
cd dotfiles
./install.sh
```
