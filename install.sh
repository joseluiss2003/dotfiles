#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

PACKAGES=(
  accountsservice
  alsa-firmware
  alsa-plugins
  alsa-utils
  awww
  base-devel
  bash-completion
  bluez
  bluez-utils
  brightnessctl
  btop
  cantarell-fonts
  cliphist
  curl
  dialog
  diffutils
  duf
  ex-vi-compat
  fastfetch
  ffmpegthumbnailer
  firefox
  fprintd
  fuzzel
  git
  github-cli
  glances
  greetd
  greetd-tuigreet
  grim
  gst-libav
  gst-plugin-pipewire
  gst-plugins-bad
  gst-plugins-ugly
  gtk4-layer-shell
  inetutils
  inotify-tools
  iw
  imv
  inxi
  iwd
  jq
  kitty
  less
  libadwaita
  libnotify
  linux-firmware
  logrotate
  lsb-release
  mako
  man-db
  man-pages
  mesa-utils
  mpv
  nano
  nano-syntax-highlighting
  nautilus
  networkmanager
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  noto-fonts-extra
  nss-mdns
  openssh
  pavucontrol
  perl
  pipewire-alsa
  pipewire-jack
  pipewire-pulse
  pinta
  playerctl
  plocate
  polkit-gnome
  poppler-glib
  power-profiles-daemon
  python
  python-defusedxml
  python-jinja
  python-packaging
  qrencode
  qt5-wayland
  qt6-wayland
  quickshell
  rsync
  rtkit
  slurp
  sof-firmware
  starship
  stow
  sudo
  sway
  swaybg
  swayidle
  swaylock
  systemd-sysvcompat
  tree
  ttf-bitstream-vera
  ttf-dejavu
  ttf-jetbrains-mono-nerd
  ttf-liberation
  ttf-opensans
  unzip
  upower
  usbutils
  wget
  which
  wireless-regdb
  wireplumber
  wl-clipboard
  wlsunset
  wtype
  xdg-desktop-portal-wlr
  xdg-user-dirs
  xdg-utils
  xf86-input-libinput
  xorg-xwayland
  yazi
  zsh
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
)

AUR_PACKAGES=(
  localsend
  spotify
)

echo "==> Comprobando distribución..."

if [[ ! -f /etc/arch-release ]]; then
    echo "ERROR: Este instalador requiere Arch Linux o una distribución basada en Arch."
    exit 1
fi

echo "==> Instalando paquetes del sistema..."

sudo pacman -S --needed "${PACKAGES[@]}"
echo
echo "==> Instalando paquetes AUR..."

AUR_HELPER=""
if command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
elif command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
else
    echo "ERROR: Se necesita yay o paru para instalar los paquetes AUR:"
    printf '  - %s\n' "${AUR_PACKAGES[@]}"
    echo
    echo "Instala un helper AUR y vuelve a ejecutar el instalador."
    exit 1
fi

"$AUR_HELPER" -S --needed "${AUR_PACKAGES[@]}"

echo
echo "==> Activando servicios..."

sudo systemctl enable bluetooth.service
sudo systemctl enable NetworkManager.service
sudo systemctl enable power-profiles-daemon.service
sudo systemctl enable greetd.service

echo
echo "==> Limpiando enlaces legacy de Stow..."

LEGACY_ROOT_LINKS=(
  fuzzel
  kitty
  mako
  quickshell
  scripts
  starship
  sway
  swayp
  install.sh
)

for name in "${LEGACY_ROOT_LINKS[@]}"; do
    target="$HOME/$name"
    expected="$DOTFILES_DIR/$name"

    if [[ -L "$target" ]] && [[ "$(readlink -f -- "$target")" == "$(realpath -- "$expected")" ]]; then
        rm -- "$target"
        echo "    ✓ Eliminado ~/$name"
    fi
done

echo
echo "==> Detectando paquetes de Stow..."

# Only these directories are actual Stow packages.
# Repository-only directories such as docs/ must never be linked into $HOME.
STOW_PACKAGES=(
  fuzzel
  kitty
  mako
  quickshell
  scripts
  starship
  sway
  swayp
  zsh
)

for package in "${STOW_PACKAGES[@]}"; do
    if [[ ! -d "$DOTFILES_DIR/$package" ]]; then
        echo "ERROR: Falta el paquete de Stow: $package"
        exit 1
    fi
done

printf '    %s\n' "${STOW_PACKAGES[@]}"

echo
echo "==> Aplicando dotfiles..."

cd "$DOTFILES_DIR"
stow -t "$HOME" "${STOW_PACKAGES[@]}"

echo
echo "==> Configurando greetd + tuigreet..."
sudo install -Dm644 /dev/stdin /etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --sessions /usr/share/wayland-sessions"
user = "greeter"
EOF

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
echo "Paquetes del sistema instalados: ${#PACKAGES[@]}"
echo "Paquetes AUR instalados: ${#AUR_PACKAGES[@]}"
echo
echo "Dotfiles instalados:"
printf '  ✓ %s\n' "${STOW_PACKAGES[@]}"
echo
echo "Servicios habilitados:"
echo "  ✓ Bluetooth"
echo "  ✓ NetworkManager"
echo "  ✓ power-profiles-daemon"
echo "  ✓ greetd"
echo
echo "Reinicia para aplicar todos los cambios:"
echo
echo "    sudo reboot"
echo
