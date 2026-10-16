#!/usr/bin/env bash
set -euo pipefail
arca_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
arca_godot="${1:-${GODOT_BIN:-$HOME/Applications/Godot_v4.5.1-stable_linux.x86_64}}"
if [[ ! -x "$arca_godot" ]]; then
  echo "Godot non trovato in: $arca_godot"
  echo "Usa: bash APRI_EDITOR_NVIDIA.sh /percorso/eseguibile-godot"
  exit 1
fi
exec env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia \
  "$arca_godot" --editor --path "$arca_dir" --display-driver x11 --rendering-method gl_compatibility
