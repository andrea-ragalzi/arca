# Sprint 02 draft

This draft records Sprint 01's automated findings. Use the two full-route F5 runs in [S1-12](docs/tasks/S1-12.md) to confirm priorities.

## Route pacing

- The ordinary-movement benchmark reaches the lift in 59.17 simulated seconds of movement input, below the 150-second walking target. One complete first-time run should take 5–10 minutes.
- Compare the two F5 victory clocks and identify whether the office detour, the three encounters, or wayfinding account for the difference. If both runs fall short of 5 minutes, scope additional route gameplay before changing the validated movement speed. If a section is slow because of confusion, address the sign, lighting or interaction there first.

## Playtest fixes

- Bring forward any reproducible soft-lock, failed checkpoint recovery or blocked interaction before tuning difficulty.
- Record ammo remaining, deaths and low-FPS areas from both runs. Use the fighting run to check resource pressure and the evasion run to check readability under pursuit.
- Compare alarm, gunfire and raptor cues on the player's audio output. Use F3 in the maintenance room, corridor, office and lift to locate any performance issue before changing render budgets.
