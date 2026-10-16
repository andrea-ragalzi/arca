#!/usr/bin/env bash
set -euo pipefail
arca_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
arca_godot="${1:-${GODOT_BIN:-$HOME/Applications/Godot_v4.5.1-stable_linux.x86_64}}"
exec env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia \
  bash "$arca_dir/AVVIA_LINUX.sh" "$arca_godot"
