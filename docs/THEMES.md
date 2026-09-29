# Creating SwayP themes

Themes are data. A new theme should not require QML changes.

## 1. Minimal structure
~~~text
swayp/.config/swayp/themes/<id>/
├── colors.toml
└── theme.toml

swayp/.config/swayp/wallpapers/<id>/
├── wallpaper-01.jpg
└── wallpaper-02.jpg
~~~

The repository theme path is the SwayP config tree under swayp/.config/swayp. The theme ID must match the wallpaper directory ID.

## 2. theme.toml
~~~toml
name = "My Theme"
description = "Short description of the visual style"
~~~

The selector discovers theme metadata automatically. Do not add themes to a hardcoded list.

## 3. colors.toml
Every theme should provide the complete SwayP palette:
~~~toml
mode = "dark"

accent = "#..."
selection = "#..."
muted = "#..."

background = "#..."
dark_background = "#..."
darker_background = "#..."
lighter_background = "#..."

foreground = "#..."
dark_foreground = "#..."
light_foreground = "#..."
bright_foreground = "#..."

red = "#..."
yellow = "#..."
orange = "#..."
green = "#..."
cyan = "#..."
blue = "#..."
magenta = "#..."
brown = "#..."

bright_red = "#..."
bright_yellow = "#..."
bright_green = "#..."
bright_cyan = "#..."
bright_blue = "#..."
bright_magenta = "#..."
~~~

The generator validates the core ANSI fields: background, foreground, muted, red, green, yellow, blue, magenta, cyan, bright_foreground, bright_red, bright_green, bright_yellow, bright_blue, bright_magenta and bright_cyan.

The additional semantic fields are part of the theme contract and should always be present.

## 4. Main color meanings
- background — canonical base background.
- dark_background — deeper surface.
- darker_background — deepest surface.
- lighter_background — raised surface/container background.
- foreground — primary text.
- light_foreground — brighter secondary text.
- dark_foreground — subdued foreground.
- muted — muted text and borders.
- accent — primary interactive/highlight color.
- selection — selection background.
- ANSI colors — terminal palette and semantic status colors.

For recognized themes, preserve the canonical palette whenever possible.

## 5. Applying a theme
~~~bash
swayp-theme-set <theme-id>
~~~

The generator updates Sway, Kitty, Starship, Fastfetch, Fuzzel, Firefox and the Quickshell palette. Firefox uses the generated `~/.config/swayp/generated/firefox-userChrome.css` and applies it to discovered Firefox profiles.

Do not edit files under ~/.config/swayp/generated/ by hand.

## 6. Wallpapers
The selector accepts JPG, JPEG, PNG, WebP and SVG.

A theme can have zero, one or many wallpapers. Multiple wallpapers are presented in one horizontal row.

A theme does not need a wallpaper to be valid. A temporary generic preview is acceptable while curating the final wallpaper set.

## 7. Theme preview
The selector automatically chooses the first supported image found in the theme wallpaper directory as its preview. Make the first image representative when possible.

## 8. Adding a recognized palette
1. Start from the canonical palette.
2. Map it into the SwayP field names.
3. Do not alter canonical colors to work around one application.
4. Fix the shared generator/component if the problem is generic.
5. Test Quickshell, Sway, Kitty and terminal output.

## 9. Checklist
~~~text
[ ] themes/<id>/colors.toml
[ ] themes/<id>/theme.toml
[ ] wallpapers/<id>/ if desired
[ ] Verify all required color fields
[ ] swayp-theme-set <id>
[ ] Quickshell
[ ] Sway focused/unfocused colors
[ ] Kitty background + ANSI colors
[ ] Starship
[ ] Fastfetch
[ ] lockscreen
[ ] Fuzzel
[ ] Firefox (`userChrome.css`)
~~~

## 10. Theme philosophy
A large catalogue is not the goal. Keep themes that are actually wanted, visually distinct, recognizable and curated.