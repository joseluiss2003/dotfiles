pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color background: "{{ colors.background.default.hex }}"
    readonly property color text: "{{ colors.on_background.default.hex }}"

    readonly property color surface: "{{ colors.surface.default.hex }}"
    readonly property color surfaceAlt: "{{ colors.surface_variant.default.hex }}"

    readonly property color textMuted: "{{ colors.on_surface_variant.default.hex }}"

    readonly property color accent: "{{ colors.primary.default.hex }}"
    readonly property color accentText: "{{ colors.on_primary.default.hex }}"

    readonly property color accentSoft: "{{ colors.primary_container.default.hex }}"

    readonly property color secondary: "{{ colors.secondary.default.hex }}"
    readonly property color tertiary: "{{ colors.tertiary.default.hex }}"

    readonly property color outline: "{{ colors.outline.default.hex }}"
    readonly property color error: "{{ colors.error.default.hex }}"
}
