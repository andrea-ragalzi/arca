# AI development environment

Configured on 2026-10-17 for the **built-in Zed Agent with the existing ChatGPT subscription**. No external Codex agent, editor replacement, extra Godot MCP, paid service, API key or test framework was installed. Gameplay and the engine are outside this task.

**Update 2026-11-24:** Codex and Claude Code are now officially supported alongside the Zed Agent, each in a separate Git worktree. See [PARALLEL_DEVELOPMENT.md](PARALLEL_DEVELOPMENT.md). The pinned MCP and its live-editor bridge below remain bound to the main checkout only. The status table records the October setup and is not re-verified here.

## Status

| Component | State | Evidence / limitation |
| --- | --- | --- |
| Godot 4.5.1 Standard, Compatibility | Verified working | `4.5.1.stable.official.f62fdbde1`; running editor and isolated headless checks |
| Zed 1.24.2; GDScript extension 0.9.0 | Installed | Existing native Linux Zed installation, not the stale Flatpak settings |
| Godot GDScript language server | Verified working | Real LSP initialization response on `127.0.0.1:6005` |
| uv 0.13.1; gdtoolkit 4.5.0 | Verified working | Existing pipx installations; gdlint/gdformat checks executed without rewriting code |
| hybridindie Godot MCP server/addon | Installed; verified working | Matched pinned sources compile on 4.5.1; standalone and native Zed calls retrieved mission hierarchy/properties in an isolated ARCA editor |
| Zed native MCP connection | Verified working against isolated editor | Real native health/project/active-scene/tree/property calls passed; server process parent verified as the running Zed editor |
| Addon in the already-open working editor | Installed, activation pending | Enable **Godot MCP** in the Plugins tab; live `project.godot` was deliberately not rewritten while the editor was open |
| Five project skills | Verified working | Original `arca-godot` retained; new MCP/debug skills loaded through Zed's native `skill` tool |
| Gameplay gate | Existing failure reproduced | Launcher 13; gameplay 42/24/52/44 pass; Regina-player baseline 301 and later concurrent-state snapshot 369 checks, both with the same 2 lateral-contact failures |

## MCP version and compatibility decision

Source: <https://github.com/hybridindie/godot-mcp>, MIT. The current README claims a Godot 4.4 minimum and recommends/validates 4.7. Testing current revision `9d48df5e4c817772dd9d0f0fe3bcb325d8549303` on 4.5.1 exposed a real parse error: `EditorInterface.get_unsaved_scenes()` is unavailable. Tags `2026.09.28`, `2026.09.30`, `2026.10.10`, `2026.10.12` and `2026.10.15` also contain that call.

The installed server and addon are therefore both pinned to upstream revision:

```text
ba5026d2a34073e8e4b68874cb8b03b691f04636
```

Its package/addon version is **2026.09.19**. This is an exact revision pin, not a claim that the newest release supports ARCA. No upstream source was patched and the engine was not upgraded. The MCP initialization metadata contains stale upstream version labels (`4.0.1` for the framework and `2026.06.01` in experimental metadata); health/package/plugin metadata identify the installed package. Do not confuse these labels with Godot's engine version.

Verified compatibility covers import/compilation, bridge connection, protocol and the listed read-only tools. It does **not** certify all mutation/runtime/export tools; those were intentionally not executed. Future upgrades must test both server and addon together on 4.5.1 in a snapshot before replacing this pin.

## Local installation and configuration

- Server checkout: `/home/andrea/Workspace/tools/godot-mcp` (outside ARCA).
- Runtime: its own `.venv`, Python 3.12.3; installed using `uv sync --project /home/andrea/Workspace/tools/godot-mcp --frozen --no-dev`.
- Locked MCP dependencies include FastMCP **4.0.1**, MCP SDK **2.1.1**; no upstream installer scripts were executed.
- Addon: `addons/godot_mcp/`, copied from that exact checkout, with original MIT `LICENSE` and `.uid` sidecars.
- Godot executable: `/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64`.
- Effective native Zed user settings: `/home/andrea/.config/zed/settings.json`.
- Backup: `/home/andrea/.config/zed/settings.json.before-arca-ai-20261017.bak`.
- `/home/andrea/.var/app/dev.zed.Zed/config/zed/settings.json` belongs to a different, inactive installation and was not changed.

Zed accepts JSONC (comments/trailing commas). Immediately after installation, the edited file was parsed as JSONC and compared structurally to the original, allowing only the MCP entry and profile tool allowlists to differ. Existing subscription/model, external-agent entries, permissions, theme and all other settings were preserved by that edit. During subsequent tool use, Zed persisted approval entries for the six native MCP inspection tools exercised here. A final comparison also found `agent.tool_permissions.tools.delete_path.default: "allow"` added during the session. These later approval changes were not part of the installer edit and were left intact rather than reverting session/user settings; the original backup remains available.

The new user-settings entry is:

```json
{
  "context_servers": {
    "godot": {
      "command": "/home/andrea/Workspace/tools/godot-mcp/.venv/bin/godot-editor-mcp",
      "args": [],
      "env": {
        "GODOT_MCP_TRANSPORT": "stdio",
        "GODOT_MCP_BRIDGE_URL": "ws://127.0.0.1:9080",
        "GODOT_MCP_GODOT_BIN": "/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64",
        "GODOT_MCP_PROJECT_DIR": "/home/andrea/Workspace/ARCA"
      }
    }
  }
}
```

The installed virtualenv entrypoint avoids PATH ambiguity, uv dependency resolution at every startup and shell startup output. Source inspection and actual protocol capture confirmed logs go to stderr; stdout carries JSON-RPC only. The bridge is loopback-only; no HTTP endpoint, credentials or external service is configured. The Python server listens; the Godot addon connects outward and retries. One server must own port 9080. Do not run another copy on that port beside Zed.

## Tool surface and profile safety

The pin provides **191 tools across 29 categories**. Only core plus inspection (**23 tools**) are initially exposed. Core includes undo/redo, so it is not entirely read-only. Discover actual schemas with `godot_get_server_info` / `godot_list_toolsets`, then enable only the needed category with `godot_enable_toolset`.

Zed's existing `enable_all_context_servers: false` remains intact. Explicit allowlists were populated from the pinned registry: Build allows all 191 tools, while Plan/Review/Diagnose allow only the 77 classified read-only tools. Server-side gating still hides unused categories. Existing Zed approval defaults remain in effect; configuration is not blanket authorization to change scenes. Newly added upstream tools will require deliberate allowlist updates.

Relevant categories: `inspection` for scene/node state; `scene_edit`/`scene_3d` for authoring; `scripts` for source/parse checks; `animation` for clip/graph inspection and authoring; `resources_edit` for resource work; `runtime`/`debugger` for execution/errors; `physics`, `analysis`, `profiling` and `testing` for focused diagnosis. Skeleton/skinning/material analysis also uses generic property/resource/class inspection and ARCA's existing tests, not an invented dedicated retargeting service.

Read-only calls actually executed over stdio include:

- `godot_get_server_info`, `godot_list_toolsets`, `godot_health_check` (`bridge_connected=true`).
- `godot_inspection_get_project_info`: ARCA, Godot 4.5.1, expected snapshot path and mission main scene.
- `godot_inspection_get_active_scene` and `godot_inspection_get_scene_tree(max_depth=2)`: `ArcaMissionRoom`.
- `godot_inspection_get_node_properties` plus built-in property reads: `Floor.collision_layer = 1`; `Player.position` approximately `(0, 0.05, -9)`.

Both paths were tested: **standalone-client → MCP → isolated Godot editor**, followed by **native Zed Agent → Zed-owned MCP → isolated Godot editor**. Native health, project identity, active scene, depth-1 hierarchy and `Floor.collision_layer` calls passed. The native project path was explicitly verified as `/home/andrea/Workspace/ARCA/.artifacts/ai-check-on7bjr1c/project/`, not the live folder. Zed owned the server process (parent PID 4871); the temporary editor was stopped after inspection, leaving the original editor untouched and the Zed server running. An initial shorter bounded editor expired between calls; retrying with a longer bound passed. No scene edits, animation playback, simulation, gameplay changes or source asset replacement were used for the MCP test.

## Skills and source review

Project-local skills use native Zed `.agents/skills/<name>/SKILL.md` frontmatter:

| Skill | Responsibility |
| --- | --- |
| `arca-godot` | Existing task execution and regression workflow; unchanged |
| `godot-3d-patterns` | GDScript, modular scenes/signals/Resources, CharacterBody3D and simple dinosaur states |
| `godot-animation-audit` | Rig/skin/material inventory, AnimationPlayer/Tree and root-motion diagnosis |
| `godot-debug-regression` | Evidence-first debugging, known failures, headless limitations and target-machine profiling |
| `godot-mcp-editor` | Native Zed MCP connection, toolset gating and safe editor inspection |

Reviewed resources:

- `shihabshahrier/Godot-Skill` at `c8bc20f876a8da241274d48461444fab86182d83`: reviewed but **not installed verbatim**. Its broad triggering/output restrictions, autoload decision rule and mandatory state-node framework conflict with ARCA's focused workflow. No complete root license notice was present in the reviewed checkout, despite an MIT frontmatter label. No source text was copied from it.
- `vl4dt/godot-skills` at `1ae280d35f2cc3931d4d8eb63f4bac82d6acf4a0`: selected concepts adapted into three focused ARCA skills; complete upstream MIT notice retained in `.agents/skills/LICENSE_GODOT_SKILLS.txt`. No package installer, third-party scripts or its overlapping Node.js MCP bridge were run/installed.
- Upstream skills were **not copied uncritically**: exclusions/corrections include 4.7-only `tween_await()`/AreaLight3D, nonexistent AnimationNodeBlendDBone2D and `printf()`, incorrect AnimationTree parameter paths, a redeclared CharacterBody3D velocity and Godot 3 loading APIs. No ECS, event-bus autoload or test framework was introduced.

Zed's native `skill` tool successfully loaded all five project skills during setup. Discovery is verified, not merely inferred from file placement.

## Repeatable checks

The existing launch/check scripts already discover the real portable 4.5.1 executable; no global `godot` symlink is necessary. Set `GODOT_BIN` for another path. With the live editor closed/idle and dependencies on PATH, the original command remains `bash scripts/check.sh`.

For an open editor, use source snapshots:

```bash
bash scripts/ai_check.sh
bash scripts/ai_check.sh --mcp
```

The first invokes the **unchanged existing gate** in a fresh ignored `.artifacts/ai-check-*/project/`, preserving its nonzero exit on failures. The second imports a fresh snapshot, enables the addon only in that copy and runs `scripts/mcp_smoke.py`: a bounded stdlib-only read-only stdio check on loopback port **19080**, without competing with Zed's 9080 server. Both retain logs and snapshots, include uncommitted source files and detect content changes during copying. Disk snapshots cannot capture unsaved Godot scene buffers. Save work before testing the latest intended scene state.

`ai_check.sh` uses system ripgrep when present; this machine still lacks `rg` on normal PATH, so it can use the already-existing `.artifacts/baseline-tools/ripgrep/usr/bin/rg`. If that local artifact is removed, install ripgrep as documented in README; the wrapper does not download packages or silently skip checks. `GODOT_MCP_SERVER_BIN` can override the local server executable for the isolated MCP check.

Zed tasks expose both snapshot checks. No format-on-save policy was changed and no mass formatting occurred. Optional non-writing checks are `gdlint <changed.gd>` and `gdformat --check <changed.gd>`; they are not replacements for Godot import/type checks.

### Actual validation and limits

- Current MCP revision failed compilation; pinned revision import/compilation passed without script errors.
- Real MCP smoke passed, including old-protocol negotiation (`2025-03-26`), hierarchy, two built-in properties and valid JSON-RPC stdout. Logs: ignored `.artifacts/ai-setup/` and `.artifacts/ai-check-on7bjr1c/`.
- Initial source snapshot full gate: launcher **13**, first-playable **42**, raptor **24**, mission **52**, ambush **44** passed; Regina-player **301 checks, 2 failures**. The failures exactly reproduce the documented left/right sole minima, approximately 6.63/5.98 cm versus the existing 2 cm requirement. No assertions were changed.
- Existing `arca/mission_room.gd` gdlint check reports **12 style problems**; gdformat `--check` would reformat that file. These are existing style findings, not setup regressions. The file was not formatted.
- Other Regina work changed files concurrently after the initial baseline snapshot and was left untouched. A later `bash scripts/ai_check.sh` run validated the snapshot/forwarding command on that copied state: launcher and all four gameplay suites still passed; the expanded Regina suite reported **369 checks, the same 2 contact failures**. Logs/snapshot: `.artifacts/ai-check-smsh8fzw/` and `.artifacts/ai-setup/final-gate.log`. Neither result certifies edits made after its snapshot or accepts the separate animation task.
- Headless checks do not validate rendered skin/lighting quality or GPU performance. No F5 gameplay acceptance is required or claimed for this tooling-only change.

## Indispensable manual completion

1. In the existing ARCA Godot editor, wait for import, then open **Project → Project Settings → Plugins** and enable **Godot MCP**. If it is not listed, refocus Godot to let its filesystem scan finish. This updates editor-plugin configuration only; do not save/reload unrelated scenes over unsaved work.
2. Zed's `godot` server is already running and native tool calls are verified; no Zed restart was needed. After enabling the live plugin, ask the built-in agent to repeat `godot_health_check` and `godot_inspection_get_project_info`. Require `bridge_connected=true` and `/home/andrea/Workspace/ARCA/` (not `.artifacts/...`) before editing live scenes. If the server later stops, restart it under **Settings → AI → MCP Servers**.

Native Zed integration with Godot 4.5.1 is verified against an isolated ARCA editor. **Only activation and identity verification in the already-open working editor remain unverified.** The terminal did not manipulate the live Plugins checkbox or rewrite its project settings.
