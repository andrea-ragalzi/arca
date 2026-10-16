#!/usr/bin/env bash
# Shared discovery for the portable Linux Godot executable.
set -euo pipefail
ARCA_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

resolve_godot() {
  ARCA_GODOT="${GODOT_BIN:-}"
  if [[ -z "$ARCA_GODOT" ]]; then
    if [[ -x "$HOME/Applications/Godot_v4.5.1-stable_linux.x86_64" ]]; then
      ARCA_GODOT="$HOME/Applications/Godot_v4.5.1-stable_linux.x86_64"
    elif command -v godot4 >/dev/null 2>&1; then
      ARCA_GODOT="$(command -v godot4)"
    elif command -v godot >/dev/null 2>&1; then
      ARCA_GODOT="$(command -v godot)"
    else
      echo 'Godot not found. Set GODOT_BIN to the Godot 4.5.1 Standard executable.' >&2
      echo 'Example: GODOT_BIN="$HOME/Applications/Godot_v4.5.1-stable_linux.x86_64" bash scripts/editor.sh --nvidia' >&2
      exit 1
    fi
  fi
  if ! ARCA_GODOT="$(command -v -- "$ARCA_GODOT")" || [[ ! -x "$ARCA_GODOT" ]]; then
    echo 'GODOT_BIN must point to an executable Godot binary.' >&2
    exit 1
  fi
  local arca_engine_version
  arca_engine_version="$("$ARCA_GODOT" --version)"
  if [[ "$arca_engine_version" != 4.5.1.* ]]; then
    echo "This project is validated with Godot 4.5.1 Standard. Found: $arca_engine_version" >&2
    exit 1
  fi
}

prepare_x11_input() {
  if [[ "${XMODIFIERS:-}" != '@im=ibus' ]] || ! command -v ibus >/dev/null 2>&1; then
    return
  fi
  local ibus_address
  ibus_address="$(ibus address 2>/dev/null)" || return 0
  # Desktop sessions can select IBus without running its input-method server.
  if [[ "$ibus_address" == '(null)' ]]; then
    export XMODIFIERS='@im=none'
  fi
}

enable_nvidia() {
  export __NV_PRIME_RENDER_OFFLOAD=1
  export __GLX_VENDOR_LIBRARY_NAME=nvidia
}
