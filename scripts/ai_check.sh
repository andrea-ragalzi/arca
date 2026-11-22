#!/usr/bin/env bash
# Validate a source snapshot without competing with the live editor's importer.
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/godot_common.sh"
if [[ $# -gt 1 || ( $# -eq 1 && "$1" != '--mcp' ) ]]; then
  echo 'Usage: bash scripts/ai_check.sh [--mcp]' >&2
  exit 2
fi
resolve_godot
export GODOT_BIN="$ARCA_GODOT"
if ! command -v rg >/dev/null && [[ -x "$ARCA_ROOT/.artifacts/baseline-tools/ripgrep/usr/bin/rg" ]]; then
  export PATH="$ARCA_ROOT/.artifacts/baseline-tools/ripgrep/usr/bin:$PATH"
fi
python3 - "$ARCA_ROOT" "$ARCA_GODOT" "${1:-}" <<'PY'
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
mode = sys.argv[3]
artifacts = root / '.artifacts'
artifacts.mkdir(exist_ok=True)
(artifacts / '.gdignore').touch(exist_ok=True)
output = Path(tempfile.mkdtemp(prefix='ai-check-', dir=artifacts))
project = output / 'project'
project.mkdir()
excluded = {'.git', '.godot', '.artifacts', '.agents', '.zed', '.env', 'build', 'exports'}
for source in root.iterdir():
    if source.name in excluded or source.name.startswith('.env.'):
        continue
    target = project / source.name
    if source.is_dir():
        shutil.copytree(source, target, symlinks=True)
    else:
        shutil.copy2(source, target)

# Detect source edits that raced the copy; never validate a mixed snapshot as current.
for copy in project.rglob('*'):
    if copy.is_file() and not copy.is_symlink():
        original = root / copy.relative_to(project)
        if not original.is_file() or hashlib.sha256(copy.read_bytes()).digest() != hashlib.sha256(original.read_bytes()).digest():
            raise SystemExit('Source changed during snapshot: ' + str(original))
print('Source snapshot and logs: ' + str(output), flush=True)
if mode == '--mcp':
    server = Path(os.environ.get('GODOT_MCP_SERVER_BIN', str(Path.home() / 'Workspace/tools/godot-mcp/.venv/bin/godot-editor-mcp')))
    if not server.is_file():
        raise SystemExit('MCP executable not found; set GODOT_MCP_SERVER_BIN to the installed server.')
    config = project / 'project.godot'
    text = config.read_text()
    plugin = 'res://addons/godot_mcp/plugin.cfg'
    if '[editor_plugins]' not in text:
        config.write_text(text + '\n[editor_plugins]\n\nenabled=PackedStringArray("' + plugin + '")\n')
    elif plugin not in text:
        raise SystemExit('Snapshot has another plugin configuration; enable Godot MCP in the live editor first.')
    with (output / 'import.log').open('w') as log:
        imported = subprocess.run([sys.argv[2], '--headless', '--editor', '--import', '--path', str(project)], stdout=log, stderr=subprocess.STDOUT, timeout=120)
    log_text = (output / 'import.log').read_text()
    if imported.returncode or 'ERROR:' in log_text:
        print(log_text)
        raise SystemExit(imported.returncode or 1)
    command = [sys.executable, str(root / 'scripts/mcp_smoke.py'), str(project), sys.argv[2], str(server), str(output)]
else:
    command = ['bash', str(project / 'scripts/check.sh')]
try:
    result = subprocess.run(command, cwd=project, timeout=900)
except subprocess.TimeoutExpired:
    raise SystemExit('Validation timed out after 900 seconds; logs remain in ' + str(output))
print('Snapshot retained: ' + str(output), flush=True)
raise SystemExit(result.returncode)
PY
