---
name: arca-godot
description: Implement and verify small gameplay changes in the ARCA Godot 4.5.1 GDScript project. Use for mission, interaction, predator, HUD or scene changes and for diagnosing ARCA gameplay bugs. Exclude generic Godot advice and unrelated repositories.
---

# Work on ARCA

1. Read the repository's `AGENTS.md`, `README.md` and `docs/DESIGN.md`. Inspect Git status and preserve existing changes.
2. Establish one observable acceptance condition from the user's task. Inspect the real scene and script inheritance before editing; start at `arca/mission_room.tscn` and `arca/mission_room.gd`.
3. Keep the official TPS movement/camera/shooting foundation. Extend the ARCA scripts and reuse existing signals/components. Keep English content, typed GDScript, tabs and Compatibility-safe effects.
4. Preserve node paths and resource identifiers. When an editor has an open modified scene, save/reload it before external edits. Never replace unsaved scene work.
5. For any delayed action, account for pause, death, restart and completion. Check interaction range, occlusion and repeated input. Treat dormant predators as non-solid and immune to stray hits.
6. Run relevant integration suites during iteration and `bash scripts/check.sh` for the final gameplay handoff. Set `GODOT_BIN` if needed. Inspect logs for parse/runtime errors; do not weaken tests to force success. Use a focused regression check for a real new behavior or reproduced bug.
7. Update affected docs and give concrete F5 playtest steps. Distinguish headless physics checks from rendered checks and user-PC performance measurements. Explain one useful concept rather than rewriting the project as a tutorial.
8. Inspect the final diff. Leave changes for review unless a commit was requested. Use the user's configured identity for requested commits; never push without authorization.

Use the plain prompts in `docs/PROMPTS.md` for bootstrap, implementation, debugging or review. Use the commands and Zed tasks in `docs/WORKFLOW.md`; no custom slash-command registry or extra service is required.
