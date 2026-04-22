#!/usr/bin/env bash

set -euo pipefail

DRY_RUN=0
FORCE=0
GPU_DETECT=1
INSTALL_DEPS=0

usage() {
  cat <<'EOF'
Usage: ./scripts/setup-dotfiles.sh [--dry-run] [--force] [--install-deps] [--skip-gpu-detect]

Options:
  --dry-run          Print actions without changing anything
  --force            Replace symlinks that point to a different target
  --install-deps     Install Arch packages needed by these dotfiles
  --skip-gpu-detect  Do not update Hyprland AQ_DRM_DEVICES from detected GPUs
  -h, --help         Show this help

What it does:
  - Optionally installs Hyprland, AGS, yazi, matugen, kitty, shell plugins, and helper tools on Arch
  - Symlinks every top-level folder in dot-config-files/ to ~/.config/
  - Symlinks dot-zshrc to ~/.zshrc
  - Backs up existing real files/folders before replacing them
  - Updates Hyprland AQ_DRM_DEVICES for the current GPU layout
EOF
}

while (($# > 0)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    --install-deps) INSTALL_DEPS=1 ;;
    --skip-gpu-detect) GPU_DETECT=0 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

try_run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@" || warn "Command failed: $*"
  fi
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONFIG_SRC="$REPO_ROOT/dot-config-files"
ZSHRC_SRC="$REPO_ROOT/dot-zshrc"
CONFIG_DST="$HOME/.config"
TS="$(date +%Y%m%d-%H%M%S)"

if [[ ! -d "$CONFIG_SRC" ]]; then
  echo "Missing directory: $CONFIG_SRC" >&2
  exit 1
fi

if [[ ! -f "$ZSHRC_SRC" ]]; then
  echo "Missing file: $ZSHRC_SRC" >&2
  exit 1
fi

aur_helper() {
  local helper

  for helper in paru yay pikaur; do
    if command_exists "$helper"; then
      printf '%s\n' "$helper"
      return 0
    fi
  done

  return 1
}

dedupe_packages() {
  local package
  local seen=" "

  for package in "$@"; do
    if [[ "$seen" == *" $package "* ]]; then
      continue
    fi

    seen+="$package "
    printf '%s\n' "$package"
  done
}

install_arch_packages() {
  local package
  local helper
  local official_packages=()
  local aur_packages=()
  local required_packages=(
    base-devel
    git
    cmake
    meson
    cpio
    pkgconf
    gcc
    nodejs
    npm
    zsh
    hyprland
    hypridle
    hyprlock
    hyprland-plugins
    hyprshot
    xdg-desktop-portal-hyprland
    kitty
    yazi
    qt5ct
    qt6ct
    qt6-base
    qt6-declarative
    qt6-quickcontrols2
    qt6-svg
    qt6-wayland
    pipewire
    pipewire-alsa
    pipewire-audio
    pipewire-jack
    pipewire-pulse
    wireplumber
    libnotify
    libcanberra
    notification-daemon
    polkit
    polkit-kde-agent
    gnome-keyring
    networkmanager
    bluez
    bluez-utils
    rfkill
    upower
    power-profiles-daemon
    brightnessctl
    playerctl
    imv
    mpv
    nano
    libreoffice-fresh
    mupdf
    xdg-utils
    firefox
    jq
    python
    fd
    ripgrep
    fzf
    zoxide
    ffmpegthumbnailer
    poppler
    imagemagick
    7zip
    unarchiver
  )
  local aur_only_packages=(
    ags
    matugen-bin
    quickshell-git
    hyprshade
  )

  if ! command_exists pacman; then
    echo "--install-deps currently supports Arch Linux only: pacman not found." >&2
    exit 1
  fi

  log "Installing Arch dependencies..."

  for package in "${required_packages[@]}"; do
    if pacman -Si "$package" >/dev/null 2>&1; then
      official_packages+=("$package")
    else
      aur_packages+=("$package")
    fi
  done

  if [[ "${#official_packages[@]}" -gt 0 ]]; then
    log "Pacman packages: ${official_packages[*]}"
    run sudo pacman -S --needed --noconfirm "${official_packages[@]}"
  fi

  mapfile -t aur_packages < <(dedupe_packages "${aur_packages[@]}" "${aur_only_packages[@]}")

  if [[ "${#aur_packages[@]}" -gt 0 ]]; then
    if helper="$(aur_helper)"; then
      log "AUR packages via $helper: ${aur_packages[*]}"
      for package in "${aur_packages[@]}"; do
        try_run "$helper" -S --needed --noconfirm "$package"
      done
    else
      warn "No AUR helper found. Install one of paru/yay/pikaur, then install: ${aur_packages[*]}"
    fi
  fi
}

ensure_git_checkout() {
  local url="$1"
  local dst="$2"

  if [[ -d "$dst/.git" ]]; then
    log "OK: $dst already cloned"
    return 0
  fi

  if [[ -e "$dst" ]]; then
    warn "SKIP: $dst exists but is not a git checkout"
    return 0
  fi

  log "Clone: $url -> $dst"
  run git clone --depth=1 "$url" "$dst"
}

install_shell_deps() {
  local custom_dir="$HOME/.oh-my-zsh/custom/plugins"

  if ! command_exists git; then
    warn "SKIP: git is required to install Oh My Zsh plugins"
    return 0
  fi

  ensure_git_checkout "https://github.com/ohmyzsh/ohmyzsh.git" "$HOME/.oh-my-zsh"
  run mkdir -p "$custom_dir"
  ensure_git_checkout "https://github.com/zsh-users/zsh-autosuggestions.git" "$custom_dir/zsh-autosuggestions"
  ensure_git_checkout "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$custom_dir/zsh-syntax-highlighting"
}

install_ags_deps() {
  if ! command_exists npm; then
    warn "SKIP: npm is required to install AGS project dependencies"
    return 0
  fi

  log "Installing AGS npm dependencies..."
  run npm --prefix "$CONFIG_SRC/ags" install
}

set_default_editor() {
  local env_dir="$HOME/.config/environment.d"
  local env_file="$env_dir/editor.conf"

  log "Setting nano as the default editor..."
  run mkdir -p "$env_dir"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] write EDITOR=nano and VISUAL=nano to $env_file"
  else
    printf 'EDITOR=nano\nVISUAL=nano\n' > "$env_file"
  fi

  export EDITOR=nano
  export VISUAL=nano
  try_run systemctl --user import-environment EDITOR VISUAL
}

enable_arch_services() {
  log "Enabling runtime services..."
  try_run sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon
  try_run systemctl --user enable --now pipewire pipewire-pulse wireplumber
}

install_deps() {
  install_arch_packages
  install_shell_deps
  install_ags_deps
  set_default_editor
  enable_arch_services
}

if [[ "$INSTALL_DEPS" -eq 1 ]]; then
  install_deps
fi

run mkdir -p "$CONFIG_DST"

link_one() {
  local src="$1"
  local dst="$2"
  local backup_dst

  if [[ -L "$dst" ]]; then
    local current
    current="$(readlink "$dst")"
    if [[ "$current" == "$src" ]]; then
      log "OK: $dst already linked"
      return 0
    fi

    if [[ "$FORCE" -eq 1 ]]; then
      log "Replacing symlink: $dst -> $current"
      run rm "$dst"
    else
      log "SKIP: $dst is a symlink to a different target ($current). Use --force to replace."
      return 0
    fi
  elif [[ -e "$dst" ]]; then
    backup_dst="${dst}.bak-${TS}"
    log "Backup: $dst -> $backup_dst"
    run mv "$dst" "$backup_dst"
  fi

  log "Link: $dst -> $src"
  run ln -s "$src" "$dst"
}

while IFS= read -r dir; do
  src="$CONFIG_SRC/$dir"
  dst="$CONFIG_DST/$dir"
  link_one "$src" "$dst"
done < <(find "$CONFIG_SRC" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

link_one "$ZSHRC_SRC" "$HOME/.zshrc"

drm_card_path() {
  local card="$1"
  local card_name
  local by_path

  card_name="$(basename -- "$card")"

  for by_path in /dev/dri/by-path/*-card; do
    [[ -e "$by_path" ]] || continue
    if [[ "$(readlink -f "$by_path")" == "/dev/dri/$card_name" ]]; then
      printf '%s\n' "$by_path"
      return 0
    fi
  done

  printf '/dev/dri/%s\n' "$card_name"
}

update_hypr_gpu_order() {
  local conf="$CONFIG_SRC/hypr/hyprland.conf"
  local card
  local vendor
  local path
  local ordered
  local replacement
  local tmp
  local primary_cards=()
  local fallback_cards=()
  local nvidia_cards=()
  local all_cards=()

  [[ "$GPU_DETECT" -eq 1 ]] || return 0

  if [[ ! -f "$conf" ]]; then
    log "SKIP: missing Hyprland config: $conf"
    return 0
  fi

  while IFS= read -r card; do
    [[ -r "$card/device/vendor" ]] || continue

    vendor="$(<"$card/device/vendor")"
    path="$(drm_card_path "$card")"

    case "$vendor" in
      0x10de) nvidia_cards+=("$path") ;;
      0x1002|0x8086) primary_cards+=("$path") ;;
      *) fallback_cards+=("$path") ;;
    esac
  done < <(find /sys/class/drm -maxdepth 1 -type l -name 'card[0-9]*' | sort -V)

  all_cards=("${primary_cards[@]}" "${fallback_cards[@]}" "${nvidia_cards[@]}")

  if [[ "${#all_cards[@]}" -lt 2 ]]; then
    log "GPU detect: single/no GPU detected, disabling AQ_DRM_DEVICES override"

    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "[dry-run] comment AQ_DRM_DEVICES in $conf"
      return 0
    fi

    tmp="$(mktemp)"
    awk '
      /^[[:space:]]*env = AQ_DRM_DEVICES,/ {
        print "# " $0
        next
      }
      { print }
    ' "$conf" > "$tmp"
    mv "$tmp" "$conf"
    return 0
  fi

  ordered="$(IFS=:; printf '%s' "${all_cards[*]}")"
  replacement="env = AQ_DRM_DEVICES,$ordered"

  log "GPU detect: $replacement"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] update AQ_DRM_DEVICES in $conf"
    return 0
  fi

  tmp="$(mktemp)"
  awk -v replacement="$replacement" '
    /^[[:space:]]*#?[[:space:]]*env = AQ_DRM_DEVICES,/ {
      if (!done) {
        print replacement
        done = 1
      }
      next
    }
    { print }
    END {
      if (!done) {
        print replacement
      }
    }
  ' "$conf" > "$tmp"
  mv "$tmp" "$conf"
}

update_hypr_gpu_order

log "Done."
