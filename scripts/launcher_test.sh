#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/godot_common.sh"
test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT

cat >"$test_dir/godot" <<'STUB'
#!/usr/bin/env bash
if [[ "${1:-}" == --version ]]; then
  echo '4.5.1.stable.official.test'
  exit 0
fi
printf 'XMODIFIERS=%s\n' "${XMODIFIERS:-}"
printf 'OFFLOAD=%s\n' "${__NV_PRIME_RENDER_OFFLOAD:-}"
printf 'GLX=%s\n' "${__GLX_VENDOR_LIBRARY_NAME:-}"
printf 'ARG=%s\n' "$@"
STUB
cat >"$test_dir/ibus" <<'STUB'
#!/usr/bin/env bash
[[ "$1" == address ]]
echo "${TEST_IBUS_ADDRESS:-(null)}"
exit "${TEST_IBUS_EXIT:-0}"
STUB
chmod +x "$test_dir/godot" "$test_dir/ibus"
export PATH="$test_dir:$PATH" GODOT_BIN="$test_dir/godot"
export XMODIFIERS='@im=ibus' XDG_SESSION_TYPE=wayland TEST_IBUS_ADDRESS='(null)'
checks=0

expect() {
  if [[ "$output" != *"$1"* ]]; then
    printf 'FAIL: %s\n%s\n' "$2" "$output" >&2
    exit 1
  fi
  checks=$((checks + 1))
}

output="$(bash "$ARCA_ROOT/scripts/editor.sh" --nvidia)"
expect 'XMODIFIERS=@im=none' 'Unavailable IBus uses the local X11 input method'
expect 'ARG=--single-window' 'XWayland editor avoids game-window embedding'
expect 'ARG=x11' 'The editor retains X11'
expect 'ARG=gl_compatibility' 'The editor retains Compatibility rendering'
expect 'OFFLOAD=1' 'NVIDIA PRIME offload is retained'
expect 'GLX=nvidia' 'The NVIDIA GLX vendor is retained'

output="$(bash "$ARCA_ROOT/scripts/run.sh")"
expect 'XMODIFIERS=@im=none' 'Standalone play also handles unavailable IBus'
expect 'ARG=--headless' 'Standalone play still imports first'
if [[ "$output" == *'ARG=--single-window'* ]]; then
  echo 'FAIL: Editor-only workaround leaked into standalone play' >&2
  exit 1
fi
checks=$((checks + 1))

output="$(TEST_IBUS_ADDRESS='unix:abstract=/tmp/test-ibus' bash "$ARCA_ROOT/scripts/editor.sh")"
expect 'XMODIFIERS=@im=ibus' 'A running IBus service is preserved'
output="$(XMODIFIERS='@im=fcitx' bash "$ARCA_ROOT/scripts/editor.sh")"
expect 'XMODIFIERS=@im=fcitx' 'Other input methods are preserved'
output="$(TEST_IBUS_EXIT=1 bash "$ARCA_ROOT/scripts/editor.sh")"
expect 'XMODIFIERS=@im=ibus' 'A failed IBus probe does not change user settings'
output="$(XDG_SESSION_TYPE=x11 bash "$ARCA_ROOT/scripts/editor.sh")"
if [[ "$output" == *'ARG=--single-window'* ]]; then
  echo 'FAIL: Native X11 editor window behavior changed' >&2
  exit 1
fi
checks=$((checks + 1))
printf 'LAUNCHER RESULT: %d checks, 0 failures\n' "$checks"
