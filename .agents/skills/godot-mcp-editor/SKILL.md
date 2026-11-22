---
name: godot-mcp-editor
description: Use ARCA's hybridindie Godot MCP from the built-in Zed Agent for live scene/node/property inspection and explicitly authorized editor operations. Covers toolset gating, the pinned Godot 4.5.1-compatible addon, connection troubleshooting and safe read-only verification.
---

# Zed Agent and Godot MCP

Read `docs/AI_ENVIRONMENT.md` for installed paths, the pinned revision, setup status and manual plugin activation. Do not install another Godot MCP or switch to an external agent.

## Connect and inspect

1. Use `godot_get_server_info()`, `godot_list_toolsets()` and `godot_health_check()`. A running Python server is not proof of `bridge_connected=true` or a correct project connection.
2. Read `godot_inspection_get_project_info()` and verify the project path is the intended ARCA folder, not an isolated test snapshot or another project.
3. Read `godot_inspection_get_active_scene()` and `godot_inspection_get_scene_tree(max_depth=2)`. Use the returned node paths verbatim; `.` denotes the edited scene root.
4. Read script variables with `godot_inspection_get_node_properties(node_path=...)`. Read built-in properties with `godot_inspection_get_node_property(node_path=..., property=...)`; check `exists` and returned values.
5. Use `godot_describe_class` / `godot_read_resource` for engine/resource inspection after checking their live schemas. Do not invent bone, animation or material tool names.

## Gated tools and safety

Only core and inspection are enabled by default. Discover the live toolsets and schemas. Request only the relevant category with `godot_enable_toolset(category=...)`; this changes server exposure, not scene content. Zed profiles also have explicit tool allowlists: a newly exposed tool must be permitted there too.

The Build profile permits the pinned server's tools, subject to Zed approval. Plan, Review and Diagnose expose only tools classified read-only. Core also includes undo/redo: it is not entirely read-only. Do not enable a mutating category or call undo/redo simply to test connectivity.

For authorized scene edits: stop the game, ensure scenes are saved, inspect before mutation, use `dry_run` previews when supported, and respect destructive `confirm` gates. Never save/reload a scene over unknown unsaved work. Do not execute GDScript, simulate input, play a scene or regenerate resources during a read-only setup check.

## Troubleshooting

- Only one server may own bridge port 9080. Keep it loopback-only; do not bind to all network interfaces. Do not run a second stdio server beside Zed's server on the same port.
- The addon connects outward to the server. If disconnected, check the Godot Plugins checkbox, matching server/addon revisions, bridge URL and editor parse errors.
- Restart the MCP server from Zed's MCP settings if needed. This conversation may require a new thread/profile refresh to receive newly configured tools; do not claim a native Zed tool call was made when only a standalone client was tested.
- Keep stdio stdout exclusively JSON-RPC. Logs belong on stderr. Do not wrap the executable with shell startup output.
- Do not update the pinned server/addon automatically: newer releases failed compilation on Godot 4.5.1. Validate upgrades in an isolated snapshot first.
