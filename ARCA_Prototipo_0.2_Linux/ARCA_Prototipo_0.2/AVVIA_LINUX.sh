#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

arca_godot="${1:-${GODOT_BIN:-}}"
if [[ -z "$arca_godot" ]]; then
  if command -v godot4 >/dev/null 2>&1; then
    arca_godot="$(command -v godot4)"
  elif command -v godot >/dev/null 2>&1; then
    arca_godot="$(command -v godot)"
  else
    echo "Scarica Godot 4.5.1 Standard: https://godotengine.org/download/archive/4.5.1-stable/"
    echo "Poi avvia: bash AVVIA_LINUX.sh /percorso/eseguibile-godot"
    exit 1
  fi
fi

arca_version="$("$arca_godot" --version)"
if [[ "$arca_version" != 4.5.1.* ]]; then
  echo "Questo prototipo è verificato con Godot 4.5.1. Versione trovata: $arca_version"
  exit 1
fi

"$arca_godot" --headless --editor --import --path .
exec "$arca_godot" --path . --display-driver x11 --rendering-method gl_compatibility
