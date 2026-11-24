# Task board

Current sprint: [SPRINT_01.md](SPRINT_01.md). Workflow: [docs/PARALLEL_DEVELOPMENT.md](docs/PARALLEL_DEVELOPMENT.md). Briefs and detailed records: [docs/tasks/](docs/tasks/README.md). Earlier history, verbatim: [docs/archive/TASK_HISTORY.md](docs/archive/TASK_HISTORY.md).

**Rule:** each branch edits only its own section below, in the same commit as its work. Keep each section to its four lines. Put details in `docs/tasks/<ID>.md` under `## Record`.

## S1-00: Baseline checkpoint and parallel-work protocol

- Status: Complete (2026-11-24)
- Branch: `main`
- Validation: Checkpoint `90ae020` and foundation commit. Full gate on `main` 625 checks / 0 failures (launcher 13, first_playable 42, raptor 59, mission 61, ambush 47, regina_player 378, economy 25).
- Blockers: -

## S1-01: Interaction contract

- Status: Merged into `main` (`02df38f`) on 2026-11-24 after review; F5 prompt check pending (see docs/tasks/S1-01.md)
- Branch: `s1/01-interactions` (ported unchanged from the agent's detached worktree `loyal-sycamore`)
- Validation: Full gate 635 checks / 0 failures (launcher 13, first_playable 42, raptor 59, mission 61, ambush 47, regina_player 378, economy 35). See docs/tasks/S1-01.md Record.
- Blockers: -

## S1-02: Raptor hit reaction and alert roar

- Status: Merged into `main` on 2026-11-24 after user approval
- Branch: `s1/02-raptor-reactions`
- Validation: Worktree gate 649 checks / 0 failures (raptor 83 = 59 existing + 24 new); mutation-checked. Details in docs/tasks/S1-02.md.
- Blockers: -

## S1-03: Multiple predators lifecycle

- Status: Merged into `main` on 2026-11-24; `multi_predator` registered in the gate
- Branch: `s1/03-multi-predator`
- Validation: Worktree gate 625/0 plus new `multi_predator_test.gd` 19/0 (mutation-checked); combined preview with S1-02: 668/0.
- Blockers: -

## S1-04: Key items and locked door

- Status: Merged into `main` on 2026-11-24
- Branch: `s1/04-key-items`
- Validation: Full gate 817/0, including mission 75/0. See docs/tasks/S1-04.md.
- Blockers: Placing the keycard and door in the route belongs to S1-10.

## S1-05: Area blockouts

- Status: Merged into `main` on 2026-11-24 after user approval
- Branch: `s1/05-areas`
- Validation: Full gate 803/0, standalone areas suite 118/0, and three X11/Compatibility stills. See docs/tasks/S1-05.md.
- Blockers: Integrated F5 walkthrough belongs to S1-10.

## S1-06: Regina death and hit reactions

- Status: Merged into `main` on 2026-11-24 after user approval
- Branch: `s1/06-regina-reactions`
- Validation: Full gate 635 checks / 0 failures, plus 93 static and 68 locomotion checks. See docs/tasks/S1-06.md Record.
- Blockers: -

## S1-07: Sleeping raptor encounter

- Status: Merged into `main` on 2026-11-24
- Branch: `s1/07-sleeping-raptor`
- Validation: Full gate 829/0, including raptor 95/0. See docs/tasks/S1-07.md.
- Blockers: Integrated F5 encounter belongs to S1-10.

## S1-08: In-memory checkpoint (stretch)

- Status: Merged into `main` on 2026-11-24
- Branch: `s1/08-checkpoint`
- Validation: Gameplay gate 1002/0, checkpoint lifecycle 12/0.
- Blockers: Integrated F5 retry check belongs to S1-12.

## S1-09: Audio hookup

- Status: Merged into `main` on 2026-11-24
- Branch: `s1/09-audio`
- Validation: Gameplay gate 1002/0, standalone audio playback 17/0 and asset import 100/0.
- Blockers: Audible mix and clipping review in S1-12.

## S1-10: Demo route integration

- Status: Route integrated into `main` on 2026-11-24
- Branch: `s1/10-integration`
- Validation: Full sprint gate 1180/0. Route 48/0, 59.17 s of scripted walking; navigation spans all four sectors.
- Blockers: Walking length is below the 150 s target. First-run time and visual acceptance remain for S1-12.

## S1-11: Title and end screens (stretch)

- Status: Merged into `main` on 2026-11-24
- Branch: `s1/11-front-end`
- Validation: Gameplay gate 1002/0, title flow 7/0 headless and 8/0 X11/Compatibility.
- Blockers: Full playthrough timing belongs to S1-12.

## S1-12: Full-route playtest

- Status: Playable on `main`; awaiting the two human F5 runs
- Branch: `main`
- Validation: Full sprint gate 1180/0; title cycle 8/0 with the X11 window driver. See docs/tasks/S1-12.md.
- Blockers: Human mission clock, soft-lock check, lighting/audio review and F3 samples. Scripted walking is below the 150 s target.

## S1-13: Readable notes

- Status: Merged into `main` on 2026-11-24
- Branch: `s1/13-notes`
- Validation: Full gate 836/0, including mission 82/0. See docs/tasks/S1-13.md.
- Blockers: Integrated F5 reading check belongs to S1-10.

## D-01: Modular environment kit

- Status: Merged into `main` on 2026-11-24 after user approval; `environment_kit` registered in the gate
- Branch: `s1/d01-environment-kit`
- Validation: Full gate 625/0. Kit suite 115/0. Two consecutive bakes matched byte for byte. Two X11/Compatibility captures saved locally.
- Blockers: -

## D-02: Gameplay prop set

- Status: Merged into `main` on 2026-11-24
- Branch: `s1/d02-props`
- Validation: Full gate 836/0, standalone prop checks 42/0, X11/Compatibility contact sheet.
- Blockers: -

## D-03: Audio preparation

- Status: Merged into `main` on 2026-11-24
- Branch: `s1/d03-audio-prep`
- Validation: Full gate 836/0, manifest and imported audio checks 100/0.
- Blockers: Live mix review belongs to S1-09.

## D-04: Optional Blender pipeline

- Status: Parked: Blender not installed
- Branch: `s1/d04-blender-pipeline`
- Validation: -
- Blockers: -

## D-05: Area dressing and atmosphere

- Status: Merged into `main` on 2026-11-24
- Branch: `s1/d05-area-dressing`
- Validation: Gameplay gate 1002/0, identical collision and markers, deterministic bake, three X11 stills.
- Blockers: F5 mood and F3 frame-rate review in S1-12.

## S2-01: Environmental continuity

- Status: Integrated into `main`
- Branch: `s2/environment-continuity`
- Validation: 1191 headless checks, including 127 area and 50 route checks. Five X11/Compatibility previews.
- Blockers: Live F5 review of detail readability and performance. See docs/tasks/S2-01.md.

## S2-02: Predator senses, physical combat and pack coordination

- Status: Integrated into `main`
- Branch: `s2/environment-continuity`
- Validation: Full gate 1385/0. Route 50, perception 9, physical combat 23, audio 18. RTX 3050 X11/Compatibility captures.
- Blockers: Live difficulty and mix review. Regina's outfit and floor recovery continued in S2-03 and S2-05.

## S2-03: Regina field outfit and Pack Training

- Status: Integrated into `main`
- Branch: `s2/environment-continuity`
- Validation: See [S2-03](docs/tasks/S2-03.md) for the gameplay checks, Godot renders and audio capture.
- Blockers: Art pass for detailed cloth, boot and strap meshes. Playtest tuning for difficulty and final mix.

## S2-04: Raptor repertoire and surface jumps

- Status: Integrated into `main`
- Branch: `s2/environment-continuity`
- Validation: See [S2-04](docs/tasks/S2-04.md) for Godot tests, rendering and pack measurements.
- Blockers: A live playthrough and final animation polish remain. The supplied dam reference is a stereo audio demo.

## S2-05: TPS surface jumps and combat mix

- Status: Integrated into `main`
- Branch: `s2/environment-continuity`
- Validation: See [S2-05](docs/tasks/S2-05.md) for player traversal, reaction, pack, mix and profiling results.
- Blockers: Human listening and a full free-play session remain. Regina's effort voice and floor pose are provisional.

## S2-06: Utility pack tactics, traversal and weapon feedback

- Status: Integrated into `main`
- Branch: `s2/environment-continuity`
- Validation: See [S2-06](docs/tasks/S2-06.md) for reproduction, tests, replay, audio and frame timings.
- Blockers: Human free-play and final animation and sound polish remain.

## S2-07: Arena acquisition and response to gunfire

- Status: Integrated into `main`
- Branch: `s2/environment-continuity`
- Validation: See [S2-07](docs/tasks/S2-07.md) for starting sight, cover and live firing checks.
- Blockers: Human balance playtest remains.

## S2-08: Predator descent recovery

- Status: Integrated into `main`
- Branch: `s2/environment-continuity`
- Validation: See [S2-08](docs/tasks/S2-08.md) for the autonomous descent regression checks.
- Blockers: Human free-play remains.

## S2-09: Occupied deck and blocked ascent

- Status: Integrated into `main`
- Branch: `s2/environment-continuity`
- Validation: 1477 headless checks passed, with 80 Pack Training checks also passing on X11/Compatibility. See [S2-09](docs/tasks/S2-09.md).
- Blockers: Free play of additional combinations remains open.

## S2-10: Connected station interiors

- Status: Implemented on `main`
- Branch: `main`
- Validation: Full gate 1501/0. X11/Compatibility route complete, 32 camera probes, 18 matched capture pairs. See [S2-10](docs/tasks/S2-10.md) for RTX 3050 Laptop measurements.
- Blockers: Human free-play review of mood, combat readability and the audio mix remains open.

## S2-11: Shared station finish and lowered ceilings

- Status: Implemented on `main`, uncommitted; awaiting human F5 review
- Branch: `main`
- Validation: Full gate 3151/0 (areas 1761, route 86 with 36 camera checks, physical combat 24). X11/Compatibility walk 290/0 including 240 camera probes. Measured heights and RTX 3050 timings in [S2-11](docs/tasks/S2-11.md).
- Blockers: Subjective mood, combat readability and chase FPS need a human pass. Aiming tight against a wall can still clip (upstream arm offset).
