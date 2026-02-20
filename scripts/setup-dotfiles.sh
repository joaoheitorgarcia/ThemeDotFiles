#!/usr/bin/env bash

set -euo pipefail

DRY_RUN=0
FORCE=0

usage() {
  cat <<'EOF'
Usage: ./scripts/setup-dotfiles.sh [--dry-run] [--force]

Options:
  --dry-run   Print actions without changing anything
  --force     Replace symlinks that point to a different target
  -h, --help  Show this help

What it does:
  - Symlinks every top-level folder in dot-config-files/ to ~/.config/
  - Symlinks dot-zshrc to ~/.zshrc
  - Backs up existing real files/folders before replacing them
EOF
}

while (($# > 0)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
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

log "Done."
