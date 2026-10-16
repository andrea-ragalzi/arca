#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/godot_common.sh"
if [[ "${1:-}" == --nvidia ]]; then enable_nvidia; shift; fi
if [[ $# -gt 0 ]]; then echo 'Usage: bash scripts/editor.sh [--nvidia]' >&2; exit 2; fi
resolve_godot
exec "$ARCA_GODOT" --editor --path "$ARCA_ROOT" --display-driver x11 --rendering-method gl_compatibility
