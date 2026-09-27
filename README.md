# SwayP

Personal Sway desktop environment built around **Sway + Quickshell**.

SwayP is a native Sway desktop shell with a modular Quickshell UI, a static theme system, generated application colors, and small user-level utilities. It evolved from an Omarchy-inspired configuration while keeping SwayP independent from the Omarchy desktop itself.

## Stack
- **Sway** — compositor and window management
- **Quickshell** — bar, panels, widgets, overlays and shared services
- **Kitty** — terminal
- **Zsh + Starship** — shell and prompt
- **Fuzzel** — application launcher
- **Mako** — notifications
- **Fastfetch** — terminal system information
- **GNU Stow** — installation and home-directory linking

## Architecture
~~~text
Theme files
    │
    ▼
swayp-theme-set
    │
    ├── Sway
    ├── Kitty
    ├── Starship
    ├── Fastfetch
    ├── Mako
    ├── Fuzzel
    └── Quickshell / lockscreen
~~~

The theme files are the source of truth. Quickshell consumes the generated semantic palette through core/Color.qml; other applications receive generated configuration under ~/.config/swayp/generated/.

There is **no Aether runtime dependency**.

## Repository layout
~~~text
.
├── docs/         # Project architecture and development guides
├── sway/         # Sway configuration
├── quickshell/   # Quickshell shell, core, UI, services and plugins
├── kitty/        # Kitty configuration
├── zsh/          # Zsh configuration
├── starship/     # Starship source/fallback configuration
├── fuzzel/       # Fuzzel configuration
├── mako/         # Mako configuration
└── scripts/      # User-level commands and generators
~~~

## Documentation
- [Architecture](docs/ARCHITECTURE.md)
- [Creating Quickshell plugins](docs/PLUGINS.md)
- [Creating and maintaining themes](docs/THEMES.md)
- [Quickshell structure](quickshell/.config/quickshell/README.md)

## Installation
~~~bash
git clone https://github.com/joseluiss2003/swayp.git
cdswayp
./install.sh
~~~

Replace the repository directory in the command above if you clone it under another name.

## Development rules
1. Keep SwayP native to Sway.
2. Keep colors data-driven; do not hardcode theme palettes into plugins.
3. Reuse qs.core.Color and qs.core.Style for Quickshell UI.
4. Keep plugins self-contained and declare their contract in manifest.json.
5. Prefer generated runtime configuration over duplicated theme logic.
6. Avoid adding dependencies unless the feature genuinely requires them.
7. When a feature becomes a reusable pattern, document it in docs/.