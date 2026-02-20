#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"

has_fullscreen=0
if command -v hyprctl >/dev/null 2>&1; then
  if command -v jq >/dev/null 2>&1; then
    if hyprctl clients -j | jq -e 'any(.[]; .fullscreen != 0)' >/dev/null; then
      has_fullscreen=1
    fi
  elif command -v python3 >/dev/null 2>&1; then
    if hyprctl clients -j | python3 - <<'PY'
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
sys.exit(0 if any(c.get("fullscreen", 0) != 0 for c in data) else 1)
PY
    then
      has_fullscreen=1
    fi
  fi
fi

media_playing=0
if command -v playerctl >/dev/null 2>&1; then
  if playerctl -a status 2>/dev/null | grep -q "Playing"; then
    media_playing=1
  fi
fi

if [[ "$has_fullscreen" -eq 0 && "$media_playing" -eq 0 ]]; then
  case "$action" in
    lock)
      hyprctl dispatch global quickshell:lock-screen
      ;;
    suspend)
      systemctl suspend
      ;;
    *)
      exit 0
      ;;
  esac
fi
