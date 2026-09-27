# SwayP first-party plugins

First-party plugins are shipped with SwayP and discovered by the shell at startup. Every plugin declares its contract in manifest.json.

## Plugin kinds
- bar — complete bar implementation.
- bar-widget — widget hosted inside a bar.
- panel — standalone panel/popup.
- service — long-lived backend service.
- menu — command/action menu.

A plugin can declare multiple kinds and expose multiple entry points.

## Reference plugins
| Plugin | Kind | Useful reference |
|---|---|---|
| clock | bar-widget | widget + popup + settings |
| audio | panel | PipeWire-backed panel |
| clipboard | bar-widget | widget + helper process |
| notifications | service | long-lived service |
| lock | service | authentication/session lock |
| menu | menu + bar-widget | multiple kinds |
| theme-selector | panel | file discovery + horizontal selection |
| bar | bar | complete bar implementation |

For the creation recipe, see [docs/PLUGINS.md](../../../docs/PLUGINS.md).

## First-party vs user plugins
First-party plugins live in quickshell/.config/quickshell/plugins/.
User/third-party plugins live in ~/.config/swayp/plugins/.

## Rules
- Use the swayp.* ID namespace.
- Keep entry points relative to the plugin directory.
- Never use absolute entry points or .. traversal.
- Reuse qs.core.Color and qs.core.Style.
- Do not hardcode theme hex values.
- Use Sway IPC/shared helpers instead of Hyprland assumptions.
- Keep shared state injected through shell/plugin infrastructure.