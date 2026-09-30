#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
EXTRAS=false

usage() {
    cat <<'EOF'
Usage: ./install.sh [--extras]

Options:
  --extras         Install personal desktop utilities and Obsidian
  -h, --help       Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --extras)
            EXTRAS=true
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
  curl
  fastfetch
  ffmpegthumbnailer
  fontconfig
  fuzzel
  greetd
  greetd-tuigreet
  grim
  iw
  inotify-tools
  iputils
  unzip
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

# Optional desktop utilities. Install with: ./install.sh --extras
# Obsidian is distributed through the AUR; the installer uses an existing
# yay/paru helper for that single package.
EXTRAS_PACKAGES=(
  bat
  btop
  evince
  fd
  file-roller
  firefox
  gedit
  git
  imv
  less
  man-db
  mpv
  nano
  openssh
  p7zip
  pciutils
  pavucontrol
  ripgrep
  rsync
  tree
  usbutils
  wget
  yazi
  zoxide
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

for command in sudo; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "ERROR: Falta el comando requerido: $command" >&2
        exit 1
    fi
done

echo "==> Instalando dependencias de SwayP..."
sudo pacman -S --needed "${PACKAGES[@]}"

if [[ "$EXTRAS" == true ]]; then
    echo
    echo "==> Instalando utilidades extra..."
    sudo pacman -S --needed "${EXTRAS_PACKAGES[@]}"

    echo
    echo "==> Instalando Obsidian..."
    "$AUR_HELPER" -S --needed obsidian
fi

echo "==> Activando servicios..."

sudo systemctl enable bluetooth.service
sudo systemctl enable NetworkManager.service
sudo systemctl enable power-profiles-daemon.service
sudo systemctl enable greetd.service

echo
echo
echo "==> Limpiando enlaces legacy de Stow..."

remove_legacy_link() {
    local target="$1"
    local expected="$2"

    if [[ -L "$target" ]] && [[ "$(readlink -m -- "$target")" == "$(readlink -m -- "$expected")" ]]; then
        rm -- "$target"
        echo "    ✓ Migrado $target"
    fi
}

# Old standalone Stow packages were migrated into swayp/. Remove their
# symlinks before applying the new unified package.
remove_legacy_link "$HOME/.config/fuzzel" "$DOTFILES_DIR/fuzzel/.config/fuzzel"
remove_legacy_link "$HOME/.config/kitty" "$DOTFILES_DIR/kitty/.config/kitty"
remove_legacy_link "$HOME/.config/quickshell" "$DOTFILES_DIR/quickshell/.config/quickshell"

# A previous migration could have left ~/.config/quickshell as a real
# directory containing only managed symlinks. That prevents Stow from
# collapsing the package into the single canonical symlink. Remove that
# legacy shell tree only when it contains no regular files.
if [[ -d "$HOME/.config/quickshell" && ! -L "$HOME/.config/quickshell" ]]; then
    if ! find "$HOME/.config/quickshell" -type f -print -quit | grep -q .; then
        rm -rf -- "$HOME/.config/quickshell"
        echo "    ✓ Eliminado árbol legacy de Quickshell"
    else
        echo "ERROR: $HOME/.config/quickshell contiene archivos reales." >&2
        echo "       Muévelos o haz copia antes de ejecutar de nuevo el instalador." >&2
        exit 1
    fi
fi

# Remove old root-level Stow links created by previous repository layouts.
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

    if [[ -L "$target" ]] && [[ "$(readlink -m -- "$target")" == "$(readlink -m -- "$expected")" ]]; then
        rm -- "$target"
        echo "    ✓ Eliminado ~/$name"
    fi
done

echo
echo "==> Detectando el paquete de Stow..."

STOW_PACKAGE="swayp"

if [[ ! -d "$DOTFILES_DIR/$STOW_PACKAGE" ]]; then
    echo "ERROR: Falta el paquete de Stow: $STOW_PACKAGE"
    exit 1
fi

echo "    $STOW_PACKAGE"

echo
echo "==> Aplicando dotfiles..."

cd "$DOTFILES_DIR"
stow -t "$HOME" "$STOW_PACKAGE"

echo
echo "==> Instalando Maple Mono NF..."

AUR_HELPER=""
if command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
elif command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
else
    echo "ERROR: SwayP requiere un helper AUR (yay o paru) para instalar Maple Mono NF." >&2
    echo "       Instala yay o paru y vuelve a ejecutar ./install.sh." >&2
    exit 1
fi

"$AUR_HELPER" -S --needed maplemono-nf

if ! fc-match -f '%{family}\n' 'Maple Mono NF' | grep -qx 'Maple Mono NF'; then
    echo "ERROR: Fontconfig no detecta Maple Mono NF después de la instalación." >&2
    exit 1
fi

echo "    ✓ Maple Mono NF disponible para SwayP."

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
if [[ "$EXTRAS" == true ]]; then
    echo "Utilidades extra instaladas: ${#EXTRAS_PACKAGES[@]} + Obsidian"
else
    echo "Extras personales: omitidos (usa --extras)"
fi
echo
echo "Dotfiles instalados:"
echo "  ✓ $STOW_PACKAGE"
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
