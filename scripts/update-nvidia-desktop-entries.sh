#!/usr/bin/env bash

set -euo pipefail

DRY_RUN=0
INCLUDE_STEAM_SHORTCUTS=1

usage() {
  cat <<'EOF'
Usage: ./scripts/update-nvidia-desktop-entries.sh [--dry-run] [--no-steam-shortcuts]

Options:
  --dry-run              Print actions without changing anything
  --no-steam-shortcuts   Do not auto-update Steam game shortcut entries
  -h, --help             Show this help

What it does:
  - Finds installed .desktop entries for GPU-heavy apps
  - Copies system entries to ~/.local/share/applications before editing them
  - Prefixes Exec= commands with NVIDIA PRIME offload environment variables
  - Adds PrefersNonDefaultGPU=true to the main Desktop Entry group
EOF
}

while (($# > 0)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --no-steam-shortcuts) INCLUDE_STEAM_SHORTCUTS=0 ;;
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

log() {
  printf '%s\n' "$*" >&2
}

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*" >&2
  else
    "$@"
  fi
}

LOCAL_APPS_DIR="$HOME/.local/share/applications"
OFFLOAD_PREFIX="env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only"

SEARCH_DIRS=(
  "$LOCAL_APPS_DIR"
  "/usr/local/share/applications"
  "/usr/share/applications"
)

TARGET_DESKTOP_IDS=(
  # Game launchers
  "steam.desktop"
  "net.lutris.Lutris.desktop"
  "minecraft-launcher.desktop"
  "com.heroicgameslauncher.hgl.desktop"
  "com.usebottles.bottles.desktop"
  "org.prismlauncher.PrismLauncher.desktop"
  "net.davidotek.pupgui2.desktop"

  # Creative and capture apps
  "com.obsproject.Studio.desktop"
  "org.kde.krita.desktop"
  "org.blender.Blender.desktop"
  "blender.desktop"
  "org.freecad.FreeCAD.desktop"
  "org.kde.kdenlive.desktop"

  # Game engines
  "org.godotengine.Godot.desktop"
  "org.godotengine.Godot4.desktop"
  "com.unity.UnityHub.desktop"

  # Emulators
  "org.duckstation.DuckStation.desktop"
  "net.pcsx2.PCSX2.desktop"
  "net.rpcs3.RPCS3.desktop"
  "org.ppsspp.PPSSPP.desktop"
  "org.DolphinEmu.dolphin-emu.desktop"
  "io.github.ryubing.Ryujinx.desktop"
  "io.github.shiiion.primehack.desktop"
)

declare -A SEEN_TARGETS=()

find_entry() {
  local id="$1"
  local dir

  for dir in "${SEARCH_DIRS[@]}"; do
    [[ -f "$dir/$id" ]] || continue
    printf '%s\n' "$dir/$id"
    return 0
  done

  return 1
}

ensure_local_entry() {
  local src="$1"
  local target="$LOCAL_APPS_DIR/$(basename -- "$src")"

  run mkdir -p "$LOCAL_APPS_DIR"

  if [[ "$src" != "$target" && ! -f "$target" ]]; then
    log "Copy: $src -> $target"
    run cp "$src" "$target"
  elif [[ "$src" != "$target" ]]; then
    log "Use existing local override: $target"
  fi

  printf '%s\n' "$target"
}

patch_entry() {
  local file="$1"
  local tmp

  if [[ "${SEEN_TARGETS[$file]:-0}" == "1" ]]; then
    return 0
  fi
  SEEN_TARGETS["$file"]=1

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "Patch: $file"
    return 0
  fi

  if ! grep -q '^Exec=' "$file"; then
    log "SKIP: $file has no Exec= line"
    return 0
  fi

  log "Patch: $file"

  tmp="$(mktemp)"

  awk -v prefix="$OFFLOAD_PREFIX" '
    function add_prefers_key() {
      if (in_desktop_entry && !seen_prefers && !added_prefers) {
        print "PrefersNonDefaultGPU=true"
        added_prefers = 1
      }
    }

    /^\[/ {
      add_prefers_key()
      in_desktop_entry = ($0 == "[Desktop Entry]")
    }

    in_desktop_entry && /^PrefersNonDefaultGPU=/ {
      print "PrefersNonDefaultGPU=true"
      seen_prefers = 1
      next
    }

    /^Exec=/ && $0 !~ /__NV_PRIME_RENDER_OFFLOAD=1/ {
      command = $0
      sub(/^Exec=/, "", command)
      print "Exec=" prefix " " command
      next
    }

    { print }

    END {
      add_prefers_key()
    }
  ' "$file" > "$tmp"

  mv "$tmp" "$file"

  if command -v desktop-file-validate >/dev/null 2>&1; then
    desktop-file-validate "$file" || true
  fi
}

patch_from_source() {
  local src="$1"
  local target

  target="$(ensure_local_entry "$src")"
  patch_entry "$target"
}

for id in "${TARGET_DESKTOP_IDS[@]}"; do
  if src="$(find_entry "$id")"; then
    patch_from_source "$src"
  else
    log "Missing: $id"
  fi
done

if [[ "$INCLUDE_STEAM_SHORTCUTS" -eq 1 ]]; then
  for dir in "${SEARCH_DIRS[@]}"; do
    [[ -d "$dir" ]] || continue

    while IFS= read -r file; do
      case "$(basename -- "$file")" in
        Proton*.desktop|Steam\ Linux\ Runtime*.desktop)
          continue
          ;;
      esac

      if grep -Eq '^Exec=.*steam[[:space:]].*steam://rungameid/' "$file"; then
        patch_from_source "$file"
      fi
    done < <(find "$dir" -maxdepth 1 -type f -name '*.desktop' -print)
  done
fi

if [[ -d "$LOCAL_APPS_DIR" ]] && command -v update-desktop-database >/dev/null 2>&1; then
  run update-desktop-database "$LOCAL_APPS_DIR"
fi

log "Done."
