# Creating SwayP Quickshell plugins

This is the recipe to follow when adding a plugin.

## 1. Choose the plugin kind
| Kind | Purpose | Typical entry point |
|---|---|---|
| bar-widget | Widget inside the bar | BarWidget.qml |
| panel | Standalone popup/panel | Panel.qml |
| service | Long-lived backend | Service.qml |
| menu | Command/action surface | Menu.qml |
| bar | Complete alternative bar | Bar.qml |

A plugin can expose multiple kinds. swayp.menu is an example.

## 2. Directory structure
Bar widget:
~~~text
plugins/my-plugin/
├── manifest.json
├── BarWidget.qml
└── Model.js          # optional
~~~

Panel:
~~~text
plugins/my-plugin/
├── manifest.json
├── Panel.qml
├── Model.js          # optional
└── components/       # optional
~~~

Service:
~~~text
plugins/my-plugin/
├── manifest.json
├── Service.qml
└── *.js              # optional helpers
~~~

Use lowercase kebab-case for the directory name.

## 3. Manifest
Every plugin needs manifest.json.

### Bar widget
~~~json
{
  "schemaVersion": 1,
  "id": "swayp.my-plugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "author": "SwayP",
  "description": "Short description",
  "kinds": ["bar-widget"],
  "entryPoints": { "barWidget": "BarWidget.qml" },
  "barWidget": {
    "displayName": "My Plugin",
    "description": "What the widget does",
    "category": "System",
    "allowMultiple": false,
    "defaultSection": "right"
  }
}
~~~

### Panel
~~~json
{
  "schemaVersion": 1,
  "id": "swayp.my-plugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "author": "SwayP",
  "description": "Short description",
  "kinds": ["panel"],
  "keepLoaded": true,
  "entryPoints": { "panel": "Panel.qml" }
}
~~~

### Service
~~~json
{
  "schemaVersion": 1,
  "id": "swayp.my-plugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "author": "SwayP",
  "description": "Short description",
  "kinds": ["service"],
  "keepLoaded": true,
  "entryPoints": { "service": "Service.qml" }
}
~~~

Entry points must be relative paths inside the plugin directory. Never use absolute paths or .. traversal.

## 4. Bar widgets
A bar widget normally starts from the shared BarWidget base:
~~~qml
import QtQuick
import Quickshell
import qs.core
import qs.ui

BarWidget {
  id: root
  moduleName: "swayp.my-plugin"

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    foreground: Color.accent
    text: "..."
  }
}
~~~

If the widget has a popup, keep the bar-facing object small and load the panel separately. Forward context such as bar, settings and anchorItem when needed.

Use clock, audio or clipboard as references for similar behaviour.

## 5. Panels
Panels summoned from the shell/bar should normally expose:
~~~qml
function open() {}
function close() {}
function toggle() {}
~~~

Reuse qs.ui surfaces and the existing PanelWindow/WlrLayershell patterns.

## 6. Services
Services are long-lived objects. Keep backend state in the service and expose a small public API.

Do not make every widget instantiate its own copy of a shared service. Shared services are injected through the shell/plugin infrastructure.

## 7. Theming
Never hardcode theme colors.

Bad: color: "#cba6f7"
Good: color: Color.accent

Use semantic roles from qs.core.Color and layout/type tokens from qs.core.Style.

Common roles include:
~~~text
Color.background
Color.backgroundDeep
Color.backgroundRaised
Color.surface
Color.surfaceAlt
Color.text
Color.textMuted
Color.accent
Color.muted
Color.success
Color.warning
Color.info
Color.error
Color.outline
Color.selection
~~~

Use Style.space(...) and existing typography/style tokens for geometry.

## 8. Sway integration
Use Sway IPC or shared Sway helpers for compositor state. Do not call Hyprland tools or IPC.

## 9. IPC
Keep IPC targets under the `swayp.*` namespace:
~~~qml
IpcHandler {
  enabled: root.ipcInstanceOwner
  target: "swayp.my-plugin"

  function toggle(): void {
    root.toggle()
  }
}
~~~

## 10. Before committing
- manifest.json is valid.
- IDs use the swayp.* namespace.
- Entry points are relative and stay inside the plugin directory.
- No hardcoded theme hex values.
- No unnecessary dependencies.
- Shared state is injected instead of duplicated.
- The plugin works after a full Quickshell restart.
- No Hyprland assumptions.
- Reusable patterns are documented.

## 11. First-party vs user plugins
First-party plugins live in swayp/.config/quickshell/plugins/.
User/third-party plugins live in ~/.config/swayp/plugins/.

Keep experiments outside the first-party tree until they are ready for production.