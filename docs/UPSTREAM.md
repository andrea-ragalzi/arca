# Upstream foundation

ARCA reuses the official [Godot Third Person Shooter Demo](https://github.com/godotengine/tps-demo) at tag [`4.5-90f2e38`](https://github.com/godotengine/tps-demo/tree/4.5-90f2e38), with Godot 4.5.1 Standard. The selected tag is deliberate; the current upstream default branch may target another engine version.

The compact project keeps the original player controller, input, camera, root motion, weapon and robot opponent with targeted ARCA fixes. The full upstream demonstration level, music and screenshot are omitted. ARCA adds its own room, health/death/restart loop, predator navigation/melee, interaction, power puzzle and mission-triggered ambush.

Original code notices remain in `LICENSE.md`. Asset credits and ARCA modification notices are recorded in `ATTRIBUTIONS.md`; ARCA additions are covered by `LICENSE_ARCA.md`. Keep those files when redistributing this project. Use the ARCA README for the current controls and launch commands.
