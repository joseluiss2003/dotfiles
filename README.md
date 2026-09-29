# SwayP 1.0

**SwayP** is a complete personal Wayland desktop shell built around **Sway + Quickshell**.

What started as a small project to customize a Sway desktop gradually grew into a complete shell: a centralized bar, panels, widgets, notifications, lockscreen, theme and wallpaper selector, system controls, shared services, generated application palettes, terminal integration and a reproducible installer.

SwayP is designed to be **Sway-native**, modular and maintainable. It takes architectural and visual inspiration from **[Omarchy](https://github.com/basecamp/omarchy), including its Quattro direction**, while remaining an independent project with its own architecture, plugin system and configuration model.

> **SwayP 1.0**
>
> A small customization project that became a complete desktop shell.

## What SwayP provides

- **Sway** as the compositor and window-management layer.
- **Quickshell** as the central desktop shell.
- A top bar with workspaces, clock, system indicators and plugin widgets.
- Panels and controls for audio, Bluetooth, network, power and other desktop services.
- Notifications and a notification center.
- Clipboard, OSD, tray, lockscreen and system utilities.
- Visual theme and wallpaper selection.
- Multi-monitor-aware shell components.
- Centralized semantic colors shared by Sway, Quickshell and applications.
- Kitty, Zsh, Starship, Fastfetch and Fuzzel integration.
- Geist typography for the Quickshell UI.
- A reproducible Arch Linux installer using GNU Stow.
- Optional desktop utilities through `./install.sh --extras`.

## Visual direction

SwayP deliberately keeps a restrained, square and compact desktop language:

- no unnecessary rounded-card-heavy UI;
- semantic colors instead of plugin-specific hardcoded palettes;
- consistent typography and spacing;
- small composable panels rather than one monolithic control center;
- visual feedback through subtle transitions and state changes.

The goal is not to reproduce another desktop environment. The goal is to build a coherent Sway desktop shell while learning from established Linux desktop projects.

## Themes

Themes are data-driven and generated from a single source of truth. The current curated collection includes:

- Black Metal
- Catppuccin
- Catppuccin Latte
- Flexoki Light
- Gruvbox
- Kanagawa
- Osaka Jade
- Rosé Pine Dawn

A theme can update the visual system across:

- Sway
- Quickshell
- Kitty
- Starship
- Fastfetch
- Fuzzel
- lockscreen/runtime palette

See [docs/THEMES.md](docs/THEMES.md) for the theme contract.

## Architecture

```text
                    ┌──────────────────────┐
                    │  Theme source files  │
                    │ colors.toml/theme.toml│
                    └──────────┬───────────┘
                               │
                               ▼
                     ┌──────────────────┐
                     │ swayp-theme-set  │
                     └────────┬─────────┘
                              │
             ┌────────────────┼────────────────┐
             ▼                ▼                ▼
          Sway / IPC      Generated app     Quickshell
                           configuration     semantic palette
                                                │
                                                ▼
                                      ┌────────────────────┐
                                      │ Central shell/core │
                                      ├────────────────────┤
                                      │ bar / panels       │
                                      │ plugins / services │
                                      │ ui / lock / OSD    │
                                      └────────────────────┘
```

All SwayP-owned desktop configuration is centralized under the single `swayp/` GNU Stow package.

The Quickshell layer is organized around:

```text
swayp/.config/quickshell/
├── shell.qml
├── core/
├── ui/
├── services/
└── plugins/
```

The architecture follows one-source-of-truth rules: shared visual primitives live in `core/` and `ui/`, feature-specific logic lives in plugins, and generated runtime files are never treated as source files.

See:

- [Architecture](docs/ARCHITECTURE.md)
- [Plugin development](docs/PLUGINS.md)
- [Theme development](docs/THEMES.md)
- [Quickshell structure](swayp/.config/quickshell/README.md)

## Installation

SwayP targets **Arch Linux and Arch-based systems**.

### Standard installation

```bash
git clone https://github.com/joseluiss2003/swayp.git
cd swayp
./install.sh
```

The installer:

1. installs SwayP's core dependencies;
2. enables the required system services;
3. migrates legacy SwayP Stow links when present;
4. applies the unified `swayp/` package with GNU Stow;
5. installs and verifies Geist v1.7.2;
6. configures greetd + tuigreet;
7. configures Zsh as the default shell.

### Optional utilities

```bash
./install.sh --extras
```

This installs the optional desktop utility set and Obsidian. Obsidian is obtained through an existing `yay` or `paru` helper.

Run:

```bash
./install.sh --help
```

for the available installer options.

## Development model

SwayP keeps the desktop shell centralized and tries to avoid duplicated responsibilities.

When adding functionality:

1. check whether an equivalent implementation already exists;
2. reuse `qs.core.Color`, `qs.core.Style` and shared services;
3. keep theme data outside QML;
4. keep plugins self-contained and declare their manifest contract;
5. avoid introducing unnecessary dependencies;
6. compare with Omarchy/Quattro when a similar desktop pattern exists;
7. validate references, syntax and runtime behaviour before considering the feature complete.

## Credits and influences

### Omarchy

SwayP owes a clear architectural and visual debt to **[Omarchy](https://github.com/basecamp/omarchy)** and its **Quattro** direction.

Omarchy was used as a reference for:

- the idea of a cohesive Linux desktop shell rather than a collection of unrelated dotfiles;
- visual hierarchy and compact desktop controls;
- theme-driven desktop configuration;
- the relationship between shell UI, utilities and system configuration.

SwayP is **not an Omarchy distribution** and is not presented as an official Omarchy project. The project uses Omarchy as a reference point while maintaining its own Sway-native architecture.

Omarchy is released under the MIT License. See the upstream [Omarchy repository](https://github.com/basecamp/omarchy) for its original project and license.

### Open-source foundations

SwayP is built on and around several open-source projects, including:

- [Sway](https://github.com/swaywm/sway)
- [Quickshell](https://github.com/quickshell-mirror/quickshell)
- [Kitty](https://sw.kovidgoyal.net/kitty/)
- [Fuzzel](https://codeberg.org/dnkl/fuzzel)
- [Starship](https://starship.rs/)
- [Fastfetch](https://github.com/fastfetch-cli/fastfetch)
- [GNU Stow](https://www.gnu.org/software/stow/)
- [Geist](https://github.com/vercel/geist-font)

Their respective licenses and upstream projects remain their own.

### AI-assisted development

**SwayP was developed with substantial AI assistance.**

AI tools were used throughout the project for architecture discussions, implementation, refactoring, debugging, repository audits, documentation, testing guidance and iterative UI development.

The project intentionally documents this openly: **SwayP is an AI-assisted desktop-shell project**, not a project presented as exclusively human-written code.

No individual authorship credit is claimed in this documentation.

## Project status

**SwayP 1.0** represents the point where the project moved beyond personal dotfile customization and became a complete, reproducible desktop shell.

The focus after 1.0 is maintenance, polishing and careful evolution rather than uncontrolled feature growth.

## License

No project-wide SwayP license is declared yet. Third-party projects, fonts and assets retain their own licenses.

For architecture and development details, start with [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
