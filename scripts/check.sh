#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/godot_common.sh"
if [[ $# -gt 0 ]]; then echo 'Usage: bash scripts/check.sh' >&2; exit 2; fi
resolve_godot
mkdir -p "$ARCA_ROOT/.artifacts/test-logs"

run_check() {
  local arca_check_name="$1"
  shift
  local arca_log="$ARCA_ROOT/.artifacts/test-logs/$arca_check_name.log"
  echo "Running $arca_check_name..."
  if ! timeout 120s "$ARCA_GODOT" "$@" >"$arca_log" 2>&1; then
    cat "$arca_log"
    return 1
  fi
  if rg -n 'SCRIPT ERROR:|ERROR:|FAIL:' "$arca_log"; then
    cat "$arca_log"
    return 1
  fi
  rg 'RESULT:|checks,|SHADOW TEST:' "$arca_log" || true
}

if ! command -v timeout >/dev/null || ! command -v rg >/dev/null; then
  echo 'The check command requires timeout (coreutils) and rg (ripgrep).' >&2
  exit 1
fi
run_check import --headless --editor --import --path "$ARCA_ROOT"
for arca_suite in first_playable raptor mission ambush; do
  run_check "$arca_suite" --headless --audio-driver Dummy --fixed-fps 60 --path "$ARCA_ROOT" -s "res://arca/tests/${arca_suite}_test.gd"
done
echo 'All gameplay suites passed. Logs: .artifacts/test-logs/'
