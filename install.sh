#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

PACKAGES=(
  git
  stow
  zsh
  starship
  sway
  swaybg
  swayidle
  quickshell
  matugen
  awww
  bluez
  bluez-utils
  brightnessctl
  cliphist
  fuzzel
  greetd
  greetd-tuigreet
  grim
  gtk4-layer-shell
  jq
  kitty
  mako
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  noto-fonts-extra
  pipewire
  pipewire-alsa
  pipewire-jack
  pipewire-pulse
  playerctl
  python
  qt5-wayland
  qt6-wayland
  slurp
  upower
  wireplumber
  wl-clipboard
  xdg-desktop-portal-wlr
  xdg-user-dirs
  xdg-utils
  xorg-xwayland
  ttf-jetbrains-mono-nerd
)

echo "==> Comprobando distribución..."

if [[ ! -f /etc/arch-release ]]; then
    echo "ERROR: Este instalador requiere Arch Linux o una distribución basada en Arch."
    exit 1
fi

echo "==> Instalando paquetes..."

sudo pacman -S --needed "${PACKAGES[@]}"

echo
echo "==> Activando servicios..."

sudo systemctl enable bluetooth.service
sudo systemctl enable NetworkManager.service
sudo systemctl enable greetd.service

echo
echo "==> Detectando paquetes de Stow..."

mapfile -t STOW_PACKAGES < <(
    find "$DOTFILES_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -printf '%f\n' |
        sort
)

if [[ ${#STOW_PACKAGES[@]} -eq 0 ]]; then
    echo "ERROR: No se encontraron paquetes de Stow."
    exit 1
fi

printf '    %s\n' "${STOW_PACKAGES[@]}"

echo
echo "==> Aplicando dotfiles..."

cd "$DOTFILES_DIR"
stow -t "$HOME" "${STOW_PACKAGES[@]}"

echo
echo "==> Configurando Zsh..."

CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

if [[ "$CURRENT_SHELL" != "/bin/zsh" ]]; then
    chsh -s /bin/zsh
    echo "Zsh configurado como shell predeterminado."
else
    echo "Zsh ya es el shell predeterminado."
fi

echo
echo "========================================"
echo " Instalación completada correctamente"
echo "========================================"
echo
echo "Dotfiles instalados:"
printf '  ✓ %s\n' "${STOW_PACKAGES[@]}"
echo
echo "Servicios habilitados:"
echo "  ✓ Bluetooth"
echo "  ✓ NetworkManager"
echo "  ✓ greetd"
echo
echo "Reinicia para aplicar todos los cambios:"
echo
echo "    sudo reboot"
echo
