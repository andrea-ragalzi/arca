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

- Status: Waiting: start after S1-04 and S1-10
- Branch: `s1/08-checkpoint`
- Validation: -
- Blockers: -

## S1-09: Audio hookup

- Status: Waiting: needs D-03 assets, S1-02 and S1-07
- Branch: `s1/09-audio`
- Validation: -
- Blockers: -

## S1-10: Demo route integration

- Status: Waiting: needs S1-01, S1-03, S1-04, S1-05, S1-07
- Branch: `s1/10-integration`
- Validation: -
- Blockers: -

## S1-11: Title and end screens (stretch)

- Status: Waiting: merge after S1-10
- Branch: `s1/11-front-end`
- Validation: -
- Blockers: -

## S1-12: Full-route playtest

- Status: Waiting: everything merged
- Branch: `main`
- Validation: -
- Blockers: -

## S1-13: Readable notes

- Status: Waiting: start after S1-01 merges
- Branch: `s1/13-notes`
- Validation: -
- Blockers: -

## D-01: Modular environment kit

- Status: Merged into `main` on 2026-11-24 after user approval; `environment_kit` registered in the gate
- Branch: `s1/d01-environment-kit`
- Validation: Full gate 625/0. Kit suite 115/0. Two consecutive bakes matched byte for byte. Two X11/Compatibility captures saved locally.
- Blockers: -

## D-02: Gameplay prop set

- Status: Waiting: start after D-01 merges
- Branch: `s1/d02-props`
- Validation: -
- Blockers: -

## D-03: Audio preparation

- Status: Ready: worktree prepared; user source approval needed before downloads
- Branch: `s1/d03-audio-prep`
- Validation: -
- Blockers: -

## D-04: Optional Blender pipeline

- Status: Parked: Blender not installed
- Branch: `s1/d04-blender-pipeline`
- Validation: -
- Blockers: -

## D-05: Area dressing and atmosphere

- Status: Waiting: needs S1-10, D-01, D-02
- Branch: `s1/d05-area-dressing`
- Validation: -
- Blockers: -
