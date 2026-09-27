#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

PACKAGES=(
  accountsservice
  alsa-firmware
  alsa-plugins
  alsa-utils
  amd-ucode
  aspell
  aspell-es
  awww
  b43-fwcutter
  base
  base-devel
  bash-completion
  bind
  bluez
  bluez-utils
  brightnessctl
  btop
  btrfs-progs
  cage
  cantarell-fonts
  cliphist
  cryptsetup
  device-mapper
  dialog
  diffutils
  dmidecode
  dmraid
  dnsmasq
  dosfstools
  downgrade
  dracut
  duf
  e2fsprogs
  efibootmgr
  efitools
  ethtool
  exfatprogs
  ex-vi-compat
  f2fs-tools
  fastfetch
  ffmpegthumbnailer
  firefox
  fprintd
  fuzzel
  git
  github-cli
  glances
  gedit
  greetd
  greetd-tuigreet
  grim
  grub
  gst-libav
  gst-plugin-pipewire
  gst-plugins-bad
  gst-plugins-ugly
  gtk4-layer-shell
  haveged
  hdparm
  hwdetect
  hwinfo
  inetutils
  inotify-tools
  imv
  inxi
  iptables
  iwd
  jfsutils
  jq
  kitty
  less
  libadwaita
  libdvdcss
  libgsf
  libnotify
  libopenraw
  linux
  linux-firmware
  linux-headers
  logrotate
  lsb-release
  lsscsi
  lvm2
  mako
  man-db
  man-pages
  matugen
  mdadm
  meld
  mesa-utils
  modemmanager
  mpv
  mtools
  nano
  nano-syntax-highlighting
  nautilus
  netctl
  networkmanager
  networkmanager-openconnect
  networkmanager-openvpn
  nfs-utils
  nilfs-utils
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  noto-fonts-extra
  nss-mdns
  ntfs-3g
  ntp
  obsidian
  openssh
  os-prober
  pacman-contrib
  pavucontrol
  perl
  pinta
  pipewire-alsa
  pipewire-jack
  pipewire-pulse
  pkgfile
  playerctl
  plocate
  polkit-gnome
  poppler-glib
  power-profiles-daemon
  python
  python-defusedxml
  python-jinja
  python-packaging
  qemu-guest-agent
  qt5-wayland
  qt6-wayland
  quickshell
  rebuild-detector
  reflector
  rsync
  rtkit
  sg3_utils
  slurp
  smartmontools
  s-nail
  sof-firmware
  spice-vdagent
  starship
  stow
  sudo
  sway
  swaybg
  swayidle
  swaylock
  sysfsutils
  systemd-sysvcompat
  texinfo
  tldr
  tree
  ttf-bitstream-vera
  ttf-dejavu
  ttf-jetbrains-mono-nerd
  ttf-liberation
  ttf-opensans
  unrar
  unzip
  upower
  usb_modeswitch
  usbutils
  vulkan-virtio
  waybar
  wget
  which
  whois
  wireless-regdb
  wireplumber
  wl-clipboard
  wlsunset
  wtype
  xdg-desktop-portal-wlr
  xdg-user-dirs
  xdg-utils
  xf86-input-libinput
  xfsprogs
  xl2tpd
  xorg-server
  xorg-xdpyinfo
  xorg-xinit
  xorg-xinput
  xorg-xkill
  xorg-xrandr
  xorg-xwayland
  xterm
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
  matugen
  quickshell
  scripts
  starship
  sway
  swayp
  install.sh
  etc
  usr
  HEAD
  config
  description
  hooks
  index
  info
  logs
  objects
  packed-refs
  refs
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

mapfile -t STOW_PACKAGES < <(
    find "$DOTFILES_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        ! -name ".git" \
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
