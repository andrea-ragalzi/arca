# ARCA project instructions

## Scope and language

- Work in this repository with Godot **4.5.1 Standard**, GDScript, Linux and the **Compatibility** renderer.
- Keep all project content in English: identifiers, comments, UI, logs, documentation and commit messages. User conversation may follow the user's language.
- Call the project and working folder **ARCA**. Use Git commits for history; do not add release numbers to titles, filenames or directories. Preserve technical engine versions and upstream tags.
- Read `README.md`, `docs/DESIGN.md` and the applicable code before changing behavior. Use `.agents/skills/arca-godot/SKILL.md` for gameplay work.

## Protect working code

- Inspect `git status` first. Preserve unrelated and uncommitted work. Do not reset, clean or overwrite it.
- Implement one bounded feature with visible acceptance conditions. Keep the tested upstream TPS movement, camera and shooting unless the task explicitly changes them.
- Prefer small scripts, explicit state and signals over new frameworks. Use tabs and typed GDScript where it improves clarity.
- Check scene inheritance and node/resource paths when editing `.tscn` or `.tres`. Save/reload editor work before external scene edits. Never overwrite unsaved Godot scene changes.
- Keep `.uid`, source-side `.import`, licenses and attributions tracked. Do not track `.godot/`, exports, logs, credentials or local artifacts.
- Add assets only with a known source and license; update `ATTRIBUTIONS.md`. Preserve original license notices.

## Runtime and checks

- Main scene: `arca/mission_room.tscn`; mission script: `arca/mission_room.gd`.
- The mission inherits the raptor room, which inherits the robot test room. The scripts follow the same inheritance chain. Do not duplicate the base controller to add a feature.
- Pause, player death, restart and completion must cancel or freeze delayed actions correctly. Interactions must respect distance, line of sight and one action per input press.
- Run `bash scripts/check.sh` after gameplay changes, or the relevant suite during iteration. Set `GODOT_BIN` if the portable executable is not discovered. Wait for active imports to finish first.
- Add focused regression checks for meaningful behavior changes; do not write tests solely to mirror cosmetic edits. Fix errors instead of hiding them or relaxing assertions.
- Headless checks validate logic and physics, not GPU performance or visual quality. State what actually ran and give manual F5 steps for visual checks.

## Handoff and Git

- Update affected documentation. Summarize resulting behavior, changed paths, checks and remaining limits; teach one useful concept when helpful.
- Leave reviewable changes. Commit only when the user asks or the task explicitly includes a checkpoint. Use configured Git identity; never invent the user's name/email.
- Do not push, publish, change remotes or upgrade the engine as a side effect of a gameplay task.
