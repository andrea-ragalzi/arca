#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/godot_common.sh"
if [[ $# -gt 0 ]]; then echo 'Usage: bash scripts/check.sh' >&2; exit 2; fi
resolve_godot
mkdir -p "$ARCA_ROOT/.artifacts/test-logs"
# Keep Godot from importing logs or snapshots stored under .artifacts.
touch "$ARCA_ROOT/.artifacts/.gdignore"

# Prefer ripgrep; fall back to POSIX grep so fresh worktrees need no extra tools.
if command -v rg >/dev/null 2>&1; then
  arca_search() { rg -n "$@"; }
  arca_list() { rg "$@"; }
else
  arca_search() { grep -nE "$@"; }
  arca_list() { grep -E "$@"; }
fi

run_check() {
  local arca_check_name="$1"
  shift
  local arca_log="$ARCA_ROOT/.artifacts/test-logs/$arca_check_name.log"
  echo "Running $arca_check_name..."
  if ! timeout 120s "$ARCA_GODOT" "$@" >"$arca_log" 2>&1; then
    cat "$arca_log"
    return 1
  fi
  if arca_search 'SCRIPT ERROR:|ERROR:|FAIL:' "$arca_log"; then
    cat "$arca_log"
    return 1
  fi
  arca_list 'RESULT:|checks,|SHADOW TEST:' "$arca_log" || true
}

if ! command -v timeout >/dev/null || ! command -v grep >/dev/null; then
  echo 'The check command requires timeout (coreutils) and grep.' >&2
  exit 1
fi
bash "$ARCA_ROOT/scripts/launcher_test.sh"
run_check import --headless --editor --import --path "$ARCA_ROOT"
for arca_suite in first_playable raptor mission ambush regina_player regina regina_locomotion economy multi_predator environment_kit areas route audio checkpoint title predator_perception physical_combat pack_arena; do
  run_check "$arca_suite" --headless --audio-driver Dummy --fixed-fps 60 --path "$ARCA_ROOT" -s "res://arca/tests/${arca_suite}_test.gd"
done
for arca_asset_suite in props audio; do
  run_check "asset_$arca_asset_suite" --headless --audio-driver Dummy --fixed-fps 60 --path "$ARCA_ROOT" -s "res://arca/tools/assets/check_${arca_asset_suite}.gd"
done
echo 'All ARCA checks passed. Logs: .artifacts/test-logs/'
