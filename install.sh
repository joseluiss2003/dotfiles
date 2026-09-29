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
    AUR_HELPER=""
    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
    elif command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
    else
        echo "ERROR: Para instalar Obsidian con --extras necesitas yay o paru." >&2
        echo "    Instala un helper AUR y vuelve a ejecutar ./install.sh --extras." >&2
        exit 1
    fi

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
echo "==> Instalando Geist v1.7.2 (Geist + Geist Mono)..."

GEIST_VERSION="1.7.2"
GEIST_URL="https://github.com/vercel/geist-font/releases/download/v1.7.2/geist-font-v1.7.2.zip"
GEIST_SHA256="7fc800d2ac6b92844895196e5041aca55d814c15db70c44f79b3b83ab82b04e2"
GEIST_CACHE_DIR="$HOME/.cache/swayp"
GEIST_ARCHIVE="$GEIST_CACHE_DIR/geist-font-v${GEIST_VERSION}.zip"
GEIST_FONT_DIR="$HOME/.local/share/fonts/Geist"
GEIST_MONO_FONT_DIR="$HOME/.local/share/fonts/GeistMono"

mkdir -p "$GEIST_CACHE_DIR" "$GEIST_FONT_DIR" "$GEIST_MONO_FONT_DIR"

if [[ ! -f "$GEIST_FONT_DIR/Geist-Regular.ttf" || ! -f "$GEIST_MONO_FONT_DIR/GeistMono-Regular.ttf" ]]; then
    echo "    Descargando Geist v${GEIST_VERSION}..."
    curl -fL --retry 3 --retry-delay 2 -o "$GEIST_ARCHIVE" "$GEIST_URL"

    echo "    Verificando SHA-256..."
    GEIST_ACTUAL_SHA256="$(sha256sum "$GEIST_ARCHIVE" | awk '{print $1}')"
    if [[ "$GEIST_ACTUAL_SHA256" != "$GEIST_SHA256" ]]; then
        echo "ERROR: La suma SHA-256 de Geist no coincide." >&2
        echo "    Esperada: $GEIST_SHA256" >&2
        echo "    Obtenida: $GEIST_ACTUAL_SHA256" >&2
        exit 1
    fi

    GEIST_EXTRACT_DIR="$(mktemp -d)"
    trap 'rm -rf "$GEIST_EXTRACT_DIR"' EXIT

    unzip -q "$GEIST_ARCHIVE" \
        'geist-font/Geist/ttf/*.ttf' \
        'geist-font/GeistMono/ttf/*.ttf' \
        -d "$GEIST_EXTRACT_DIR"

    while IFS= read -r font; do
        install -Dm644 "$font" "$GEIST_FONT_DIR/$(basename "$font")"
    done < <(find "$GEIST_EXTRACT_DIR/geist-font/Geist/ttf" -maxdepth 1 -type f -name '*.ttf' -print)

    while IFS= read -r font; do
        install -Dm644 "$font" "$GEIST_MONO_FONT_DIR/$(basename "$font")"
    done < <(find "$GEIST_EXTRACT_DIR/geist-font/GeistMono/ttf" -maxdepth 1 -type f -name '*.ttf' -print)

    rm -rf "$GEIST_EXTRACT_DIR"
    trap - EXIT
else
    echo "    Geist v${GEIST_VERSION} ya está instalado."
fi

fc-cache -f "$GEIST_FONT_DIR" "$GEIST_MONO_FONT_DIR"

if ! fc-match -f '%{family}\n' Geist | grep -qx 'Geist'; then
    echo "ERROR: Fontconfig no detecta Geist después de la instalación." >&2
    exit 1
fi

if ! fc-match -f '%{family}\n' 'Geist Mono' | grep -qx 'Geist Mono'; then
    echo "ERROR: Fontconfig no detecta Geist Mono después de la instalación." >&2
    exit 1
fi

echo "    ✓ Geist v1.7.2 y Geist Mono disponibles para SwayP."

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
