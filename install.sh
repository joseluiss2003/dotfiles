#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPER_STATE="$HOME/.local/state/wallpaper/current"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

PACKAGES=(
    git
    stow

    sway
    swayidle
    kitty
    fuzzel
    mako
    quickshell
    matugen
    awww
    hyprlock

    zsh
    starship

    playerctl
    wl-clipboard
    cliphist

    networkmanager
    glib2
    curl
    xdg-utils
    polkit

    xdg-desktop-portal
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
    xorg-xwayland

    ttf-jetbrains-mono-nerd
)

info() {
    printf '\n\033[1;32m==>\033[0m %s\n' "$1"
}

warn() {
    printf '\n\033[1;33m[!]\033[0m %s\n' "$1"
}

error() {
    printf '\n\033[1;31m[ERROR]\033[0m %s\n' "$1" >&2
    exit 1
}

command -v pacman >/dev/null 2>&1 \
    || error "Este script está pensado para Arch Linux."

if [[ "$EUID" -eq 0 ]]; then
    error "Ejecuta el script como usuario normal, no como root."
fi

info "Actualizando Arch"

sudo pacman -Syu --needed

info "Instalando paquetes"

sudo pacman -S --needed "${PACKAGES[@]}"

info "Creando directorios"

mkdir -p \
    "$HOME/.local/bin" \
    "$HOME/.local/state/wallpaper" \
    "$WALLPAPER_DIR" \
    "$HOME/.config/hypr"

info "Instalando dotfiles con GNU Stow"

cd "$DOTFILES_DIR"

stow \
    fuzzel \
    kitty \
    mako \
    matugen \
    quickshell \
    starship \
    sway \
    wallpaper \
    zsh

info "Configurando Zsh como shell por defecto"

ZSH_PATH="$(command -v zsh)"

if [[ "${SHELL:-}" != "$ZSH_PATH" ]]; then
    chsh -s "$ZSH_PATH"
fi

info "Preparando wallpaper"

WALLPAPER=""

if [[ $# -ge 1 ]]; then
    WALLPAPER="$1"
fi

if [[ -z "$WALLPAPER" ]]; then
    if [[ -f "$WALLPAPER_STATE" ]]; then
        WALLPAPER="$(cat "$WALLPAPER_STATE")"
    fi
fi

if [[ -n "$WALLPAPER" && ! -f "$WALLPAPER" ]]; then
    warn "El wallpaper indicado no existe: $WALLPAPER"
    WALLPAPER=""
fi

if [[ -z "$WALLPAPER" ]]; then
    warn "No hay wallpaper inicial configurado."
    echo
    echo "Pon una imagen en:"
    echo "  $WALLPAPER_DIR"
    echo
    echo "y ejecuta después:"
    echo "  $HOME/.local/bin/wallpaper-picker"
    echo
else
    info "Aplicando Matugen al wallpaper"

    printf '%s\n' "$WALLPAPER" > "$WALLPAPER_STATE"

    matugen image "$WALLPAPER"

    if [[ -x "$HOME/.local/bin/update-hyprlock" ]]; then
        "$HOME/.local/bin/update-hyprlock"
    fi
fi

info "Comprobando configuración"

if command -v sway >/dev/null 2>&1; then
    sway -C -c "$HOME/.config/sway/config" >/dev/null
    echo "Sway: OK"
fi

if command -v hyprlock >/dev/null 2>&1; then
    if [[ -f "$HOME/.config/hypr/hyprlock.conf" ]]; then
        echo "Hyprlock: OK"
    else
        warn "Hyprlock instalado pero todavía no hay hyprlock.conf."
    fi
fi

echo
printf '\033[1;32m========================================\033[0m\n'
printf '\033[1;32m      DOTFILES INSTALL COMPLETADO      \033[0m\n'
printf '\033[1;32m========================================\033[0m\n'
echo
echo "Repo:       $DOTFILES_DIR"
echo "Shell:      $ZSH_PATH"
echo "Wallpaper:  ${WALLPAPER:-pendiente}"
echo
echo "Reinicia la sesión para entrar en Sway con toda la configuración."
echo
