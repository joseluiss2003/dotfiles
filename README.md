# SwayP

Personal Sway desktop environment built around **Sway + Quickshell + Matugen**.

SwayP is a native Sway setup with a modular Quickshell shell, dynamic Matugen theming, and a small collection of user-level utilities. The project is being separated from its Omarchy origins while keeping the parts that are useful for this environment.

## Stack

- **Sway** — compositor and window management
- **Quickshell** — bar, panels, widgets and desktop UI
- **Matugen** — central dynamic theme generator
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
├── matugen/    # Theme source and generated configuration templates
├── kitty/      # Kitty configuration
├── zsh/        # Zsh configuration
├── starship/   # Static Starship fallback
├── fuzzel/     # Application launcher
├── mako/       # Notifications
└── scripts/    # User-level utility commands
```

## Design goals

- Native Sway integration instead of compositor-specific assumptions.
- Matugen as the single source for dynamic colors.
- Small, composable Quickshell components.
- Clear separation between core services, UI and plugins.
- No dependency on the Omarchy desktop itself.

## Installation

The repository is managed with GNU Stow.

```bash
git clone https://github.com/joseluiss2003/dotfiles.git
cd dotfiles
./install.sh
```

> SwayP is under active migration and cleanup. The `migration/swayp` branch is the workspace for structural changes before they reach `master`.
