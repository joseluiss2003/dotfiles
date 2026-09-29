# SwayP theme wallpaper pools

Each theme can ship its own wallpaper pool:

- `black-metal/`
- `catppuccin/`
- `gruvbox/`
- `kanagawa/`
- `osaka-jade/`
- `rose-pine-dawn/`

The wallpaper picker prefers the pool belonging to the currently active theme and falls back to `~/Pictures/wallpapers` when that pool is empty.

A theme does not need a wallpaper pool to be valid. When a pool is present, the first supported image is used as the default wallpaper and selector preview.
