#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${HYPRLAND_BIN:-}" ]]; then
  if command -v start-hyprland >/dev/null 2>&1; then
    HYPRLAND_BIN="$(command -v start-hyprland)"
  else
    HYPRLAND_BIN="/usr/bin/Hyprland"
  fi
fi

if [[ ! -x "$HYPRLAND_BIN" ]]; then
  printf 'Hyprland launcher not found: %s\n' "$HYPRLAND_BIN" >&2
  exit 1
fi

card_name() {
  local card="$1"
  basename -- "$card"
}

drm_card_node() {
  local card="$1"
  local name

  name="$(card_name "$card")"
  [[ "$name" =~ ^card[0-9]+$ ]] || return 1
  [[ -e "/dev/dri/$name" ]] || return 1

  printf '/dev/dri/%s\n' "$name"
}

pci_slot() {
  local card="$1"
  local device_path

  device_path="$(readlink -f "$card/device" 2>/dev/null || true)"
  [[ -n "$device_path" ]] || return 1

  basename -- "$device_path"
}

gpu_label() {
  local card="$1"
  local slot

  slot="$(pci_slot "$card" || true)"
  if [[ -n "$slot" ]] && command -v lspci >/dev/null 2>&1; then
    lspci -D -s "$slot" 2>/dev/null || true
  fi
}

configure_drm_devices() {
  local card
  local path
  local vendor
  local label
  local ordered
  local iris_cards=()
  local intel_cards=()
  local amd_cards=()
  local fallback_cards=()
  local nvidia_cards=()
  local all_cards=()

  for card in /sys/class/drm/card[0-9]*; do
    [[ -e "$card" ]] || continue
    [[ "$(card_name "$card")" =~ ^card[0-9]+$ ]] || continue
    [[ -r "$card/device/vendor" ]] || continue

    vendor="$(<"$card/device/vendor")"
    path="$(drm_card_node "$card" || true)"
    [[ -n "$path" ]] || continue
    label="$(gpu_label "$card")"

    case "$vendor" in
      0x10de) nvidia_cards+=("$path") ;;
      0x8086)
        if [[ "$label" =~ [Ii]ris|[Xx]e[[:space:]]+[Gg]raphics ]]; then
          iris_cards+=("$path")
        else
          intel_cards+=("$path")
        fi
        ;;
      0x1002) amd_cards+=("$path") ;;
      *) fallback_cards+=("$path") ;;
    esac
  done

  all_cards=("${iris_cards[@]}" "${intel_cards[@]}" "${amd_cards[@]}" "${fallback_cards[@]}" "${nvidia_cards[@]}")

  if [[ "${#all_cards[@]}" -lt 2 ]]; then
    unset AQ_DRM_DEVICES
    return 0
  fi

  ordered="$(IFS=:; printf '%s' "${all_cards[*]}")"
  export AQ_DRM_DEVICES="$ordered"
}

if [[ "${1:-}" == "--print-drm-devices" ]]; then
  configure_drm_devices
  printf '%s\n' "${AQ_DRM_DEVICES:-}"
  exit 0
fi

configure_drm_devices

exec "$HYPRLAND_BIN" "$@"