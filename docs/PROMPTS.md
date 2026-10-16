# Agent prompts

Paste one prompt at a time into the Codex agent in Zed, with the entire ARCA folder open. These are plain prompts; they do not require custom slash commands. All generated project content must be English. You can still ask questions in Italian.

## Bootstrap a new conversation

```text
This folder is ARCA, a Godot 4.5.1 Standard / GDScript project on Linux.
Read AGENTS.md, .agents/skills/arca-godot/SKILL.md, README.md,
docs/DESIGN.md and docs/VALIDATION.md before working.
Check Git status first. If Git is not initialized, initialize a main branch
and prepare an initial checkpoint; use my configured Git identity, never
invent one. If identity is missing, give me the two local config commands.
Do not overwrite existing work. Keep code, comments, UI and documentation
in English. Do not add release numbers to the project or folder name.
Explain the current scene/script inheritance and the power-triggered ambush.
Do not change gameplay until I give you the next task.
```

## Implement one feature

```text
Read AGENTS.md and .agents/skills/arca-godot/SKILL.md.
Implement this task: [describe one feature].
Acceptance conditions: [what I must be able to do or observe].
Inspect the existing scenes first, keep the current TPS controller and
Compatibility renderer, and avoid unrelated rewrites. Implement the change,
run the relevant checks, update the docs and give me exact F5 playtest steps.
List changed files and explain one useful GDScript concept. Leave the changes
ready for review; do not commit or push unless I ask.
```

## Diagnose a bug

```text
Read AGENTS.md. Here is the observed behavior: [describe].
Expected behavior: [describe]. Reproduction steps: [steps].
Log: [paste the first relevant error and nearby lines].
Reproduce the failure in the actual project, fix the cause, and verify the
affected behavior. Add a focused regression check when appropriate. Report
what you reproduced, changed and tested. Do not claim a visual check from
headless tests.
```

## Review the current change

```text
Read AGENTS.md and inspect the working diff. Review for actual bugs,
Godot 4.5.1 Compatibility issues, broken node/resource paths, and regressions
in pause, death, restart, interaction and ambush timing. Give concrete findings
with paths and practical impact. Make no edits during this review.
```

## Learn from the code

```text
Explain arca/mission_room.gd in small sections for a Python backend developer
learning Godot. Show how signals connect the fuse, panel, door and ambush.
Explain res://, @export, @onready, scene inheritance and _physics_process
using this code. Do not rewrite it. Finish with one small editor exercise.
```

## Create a checkpoint

```text
Review Git status and the intended changes. Confirm the relevant checks and
playtest results, stage only the intended files and create a concise English
commit using my configured identity. Do not push or modify remotes.
```
