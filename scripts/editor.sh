#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/godot_common.sh"
if [[ "${1:-}" == --nvidia ]]; then enable_nvidia; shift; fi
if [[ $# -gt 0 ]]; then echo 'Usage: bash scripts/editor.sh [--nvidia]' >&2; exit 2; fi
resolve_godot
prepare_x11_input
editor_window_args=()
# Avoid Godot 4.5.1's X11 embedded-window teardown error under XWayland.
if [[ "${XDG_SESSION_TYPE:-}" == wayland ]]; then
  editor_window_args+=(--single-window)
fi
exec "$ARCA_GODOT" --editor --path "$ARCA_ROOT" --display-driver x11 --rendering-method gl_compatibility "${editor_window_args[@]}"
