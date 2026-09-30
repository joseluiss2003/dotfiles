# SwayP visual language

## Purpose

SwayP is a desktop shell for Sway, not a terminal application. Its UI borrows the
clarity and information density of mature TUI applications without pretending to
be one.

This is deliberately a break from treating Omarchy/Quattro as the visual
destination. Quattro remains a useful architectural reference, but SwayP owns
its visual grammar.

## Core idea

The shell should feel like a **terminal-native desktop**:

- compact rather than spacious;
- square rather than card-like;
- information-dense rather than decorative;
- keyboard-first without excluding the mouse;
- typographic hierarchy before ornament;
- state made explicit through small, repeatable symbols;
- selection made obvious with a cursor marker and restrained fill;
- icons used for meaning and action, not as decoration on every label.

## TUI principles adapted to SwayP

### 1. The cursor is a first-class visual

Interactive rows use a single panel cursor state. The primary selection affordance
is the ">" marker, followed by a subtle state fill.

A dense list should remain readable when several rows are visible at once. A full
border around every selected row is therefore not the default.

CursorSurface owns this behavior so plugins do not invent independent selection
systems.

### 2. Sections read like terminal views

Section headings are compact, uppercase, monospace labels with a shared marker.
They should establish hierarchy without becoming cards or banners.

PanelSectionHeader is the shared implementation.

### 3. State has a vocabulary

The visual language reserves a small set of compact state symbols:

- "●" on / active;
- "○" off / inactive;
- "◐" partial / transitional;
- "×" error / unavailable.

The exact glyphs remain style tokens so the semantic meaning is centralized.

### 4. Icons are semantic

Nerd Font glyphs are kept in qs.ui.Icons. Plugins should ask for semantic icons
rather than embedding Unicode literals in their own QML/JS.

This keeps the icon language stable across themes and lets SwayP change its visual
vocabulary without rewriting plugin behavior.

### 5. Information density is intentional

Borrow the useful characteristics of TUIs:

- compact rows;
- small labels plus strong values;
- tables and aligned metadata where useful;
- explicit current/selected states;
- short action hints;
- predictable keyboard navigation.

Do not add density merely to make the UI look technical. Every extra symbol must
carry information or improve navigation.

### 6. Color is structural, not decorative

Color, Style, and Border remain the authorities for visual state. New
components should use semantic roles and state helpers rather than theme-specific
hex values.

Accent color should identify interaction, focus, or important state. The idle UI
should remain quiet enough that active information stands out.

## What SwayP is not trying to do

SwayP should not become:

- a clone of btop, lazygit, yazi, k9s, or any other TUI;
- a collection of ASCII boxes around every component;
- a dashboard where every element is permanently highlighted;
- an icon-heavy desktop where text hierarchy disappears;
- a second styling system beside Color / Style / Border.

The reference applications provide principles, not components or code to copy.

## Reference family

The visual study for this language includes:

- btop — dense pane composition, compact labels, status-oriented information;
- lazygit — focused panels, context-sensitive actions, keyboard navigation;
- yazi — restrained selection, compact metadata, persistent status information;
- k9s — command-driven navigation, tabular views, explicit current context.

Their common strength is not a specific color scheme. It is the way state,
navigation, hierarchy, and information density are made visible with very little
chrome.

## Implementation ownership

- qs.core.Color — semantic color roles;
- qs.core.Style — spacing, typography, interaction/state tokens, TUI markers;
- qs.core.Border — border geometry and border semantics;
- qs.ui.Icons — shared icon vocabulary;
- qs.ui.CursorSurface — row selection/cursor affordance;
- qs.ui.PanelSectionHeader — section-heading grammar;
- plugin panels — layout and domain-specific information only.

A plugin should extend these primitives before creating a parallel visual pattern.

## Evolution rule

When a visual problem appears, first classify it as layout, spacing, typography,
color, border, hierarchy, or behavior. Change the smallest owning primitive that
solves the problem.

The goal is for a person to recognize a SwayP surface before they recognize which
plugin produced it.
