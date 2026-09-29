#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WITH_EXTRAS=false

usage() {
    cat <<'EOF'
Usage: ./install.sh [--with-extras]

Options:
  --with-extras    Install personal desktop utilities and AUR applications
  -h, --help       Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --with-extras)
            WITH_EXTRAS=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: Opción desconocida: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

# Core dependencies: required by SwayP itself or by features wired into the
# shipped Sway/Quickshell configuration.
PACKAGES=(
  awww
  bluez
  bluez-utils
  brightnessctl
  cliphist
  curl
  fastfetch
  ffmpegthumbnailer
  fuzzel
  greetd
  greetd-tuigreet
  grim
  iw
  iputils
  jq
  kitty
  libnotify
  nautilus
  networkmanager
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  noto-fonts-extra
  pinta
  pipewire
  pipewire-alsa
  pipewire-pulse
  playerctl
  power-profiles-daemon
  python
  qt6-wayland
  quickshell
  qrencode
  rtkit
  slurp
  starship
  stow
  sway
  swaybg
  swayidle
  swaylock
  ttf-dejavu
  ttf-jetbrains-mono-nerd
  ttf-liberation
  upower
  wireplumber
  wl-clipboard
  wlsunset
  wtype
  xdg-desktop-portal-wlr
  xdg-user-dirs
  xdg-utils
  xorg-xwayland
  zsh
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
)

# Convenience software kept separate from the SwayP runtime. This preserves
# the previous "personal machine" setup without making those applications
# mandatory on every SwayP installation.
EXTRA_PACKAGES=(
  alsa-firmware
  alsa-plugins
  alsa-utils
  base-devel
  bash-completion
  btop
  cantarell-fonts
  dialog
  diffutils
  duf
  ex-vi-compat
  firefox
  fprintd
  git
  github-cli
  glances
  gst-libav
  gst-plugin-pipewire
  gst-plugins-bad
  gst-plugins-ugly
  imv
  inxi
  iwd
  less
  linux-firmware
  logrotate
  lsb-release
  man-db
  man-pages
  mesa-utils
  mpv
  nano
  nano-syntax-highlighting
  nss-mdns
  openssh
  pavucontrol
  perl
  pipewire-jack
  plocate
  poppler-glib
  rsync
  sof-firmware
  sudo
  tree
  ttf-bitstream-vera
  ttf-opensans
  unzip
  usbutils
  wget
  which
  wireless-regdb
  yazi
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

if [[ $EUID -eq 0 ]]; then
    echo "ERROR: Ejecuta este instalador como tu usuario normal, no como root." >&2
    exit 1
fi

for command in sudo stow; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "ERROR: Falta el comando requerido: $command" >&2
        exit 1
    fi
done

echo "==> Instalando dependencias de SwayP..."
sudo pacman -S --needed "${PACKAGES[@]}"

if [[ "$WITH_EXTRAS" == true ]]; then
    echo
    echo "==> Instalando extras personales..."
    sudo pacman -S --needed "${EXTRA_PACKAGES[@]}"

    echo
    echo "==> Instalando aplicaciones AUR..."
    AUR_HELPER=""
    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
    elif command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
    else
        echo "ERROR: Se necesita yay o paru para instalar los extras AUR:"
        printf '  - %s\n' "${AUR_PACKAGES[@]}"
        echo
        echo "Instala un helper AUR o ejecuta el instalador sin --with-extras."
        exit 1
    fi

    "$AUR_HELPER" -S --needed "${AUR_PACKAGES[@]}"
fi

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
  quickshell
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
echo "==> Limpiando enlaces de Stow legacy..."

remove_legacy_link() {
    local target="$1"
    local expected="$2"

    if [[ -L "$target" ]] && [[ "$(readlink -f -- "$target")" == "$(realpath -- "$expected")" ]]; then
        rm -- "$target"
        echo "    ✓ Migrado $target"
    fi
}


echo
echo "==> Detectando paquetes de Stow..."

STOW_PACKAGES=(
  fuzzel
  kitty
  quickshell
  swayp
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
echo "Dependencias SwayP instaladas: ${#PACKAGES[@]}"
if [[ "$WITH_EXTRAS" == true ]]; then
    echo "Extras personales instalados: ${#EXTRA_PACKAGES[@]}"
    echo "Aplicaciones AUR instaladas: ${#AUR_PACKAGES[@]}"
else
    echo "Extras personales: omitidos (usa --with-extras)"
fi
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
