#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"

has_fullscreen=0
if command -v hyprctl >/dev/null 2>&1; then
  clients_json="$(hyprctl clients -j 2>/dev/null || true)"
  monitors_json="$(hyprctl monitors -j 2>/dev/null || true)"

  if command -v jq >/dev/null 2>&1; then
    if jq -e -n --argjson clients "$clients_json" --argjson monitors "$monitors_json" '
      ($monitors | map(.activeWorkspace.id)) as $visible_workspaces
      | any($clients[]; (.fullscreen // 0) != 0 and ($visible_workspaces | index(.workspace.id)))
    ' >/dev/null 2>&1; then
      has_fullscreen=1
    fi
  elif command -v python3 >/dev/null 2>&1; then
    if CLIENTS_JSON="$clients_json" MONITORS_JSON="$monitors_json" python3 - <<'PY'
import json, os, sys
try:
    clients = json.loads(os.environ["CLIENTS_JSON"])
    monitors = json.loads(os.environ["MONITORS_JSON"])
except Exception:
    sys.exit(1)
visible_workspaces = {
    m.get("activeWorkspace", {}).get("id")
    for m in monitors
}
sys.exit(0 if any(
    c.get("fullscreen", 0) != 0
    and c.get("workspace", {}).get("id") in visible_workspaces
    for c in clients
) else 1)
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

if [[ "$action" == "status" ]]; then
  printf 'visible_fullscreen=%s\nmedia_playing=%s\n' "$has_fullscreen" "$media_playing"
  exit 0
fi

if [[ "$has_fullscreen" -eq 0 && "$media_playing" -eq 0 ]]; then
  case "$action" in
    dim)
      hyprshade on dim
      ;;
    dpms-off)
      hyprctl dispatch dpms off
      ;;
    lock)
      if ! ags request lock >/dev/null 2>&1; then
        hyprlock
      fi
      ;;
    suspend)
      systemctl suspend
      ;;
    *)
      exit 0
      ;;
  esac
fi
