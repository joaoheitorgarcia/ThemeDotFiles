#!/usr/bin/env bash

set -euo pipefail

DRY_RUN=0
FORCE=0
GPU_DETECT=1

usage() {
  cat <<'EOF'
Usage: ./scripts/setup-dotfiles.sh [--dry-run] [--force] [--skip-gpu-detect]

Options:
  --dry-run          Print actions without changing anything
  --force            Replace symlinks that point to a different target
  --skip-gpu-detect  Do not update Hyprland AQ_DRM_DEVICES from detected GPUs
  -h, --help         Show this help

What it does:
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
