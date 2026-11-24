# Credits and licenses

## Official TPS foundation

**Godot Third Person Shooter Demo**, Godot Engine contributors.
Source: <https://github.com/godotengine/tps-demo/tree/4.5-90f2e38>.
The original code is MIT; its complete notice is preserved in `LICENSE.md`.

Models, textures, animations, effects and audio distributed upstream:
Copyright (c) 2018 Juan Linietsky, Fernando Miguel Calabró.
Creative Commons Attribution 3.0: <https://creativecommons.org/licenses/by/3.0/>.
The upstream notice credits original Substance Painter materials provided by GameTextures.com.

Upstream music is credited to Christian Fernando Perucchi under CC-BY 3.0. This compact project does not include the demonstration level's music file.

ARCA adaptations include the room and HUD, health component, offline integration, collision/laser/restart fixes, and renaming an unused player GLB animation clip. The player's remaining geometry, rig and animations are preserved. ARCA code and new scenes are MIT under `LICENSE_ARCA.md`; derived assets retain the attribution above.

## Gameplay predator

**"PBR Velociraptor (Animated)"** by **Ferocious Industries**.
Source: <https://skfb.ly/oHoUE> / <https://sketchfab.com/3d-models/pbr-velociraptor-animated-8f1744af7b0847a2aabe3df90be802f0>.
Author: <https://sketchfab.com/ferociousindustries.matthias>.
Licensed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**: <http://creativecommons.org/licenses/by/4.0/>.
The original download notice is preserved in `arca/assets/raptor/ferocious/source/license.txt`.

The official user-supplied Sketchfab glTF, binary, textures, rig and source clips are unchanged. Godot converts its specular/glossiness materials for Compatibility rendering. ARCA's separate derived gameplay library selects six real source clips, retimes presentation, trims the bite's initial preparation and anchors root translation to preserve the existing physics/combat contract; see `arca/assets/raptor/ferocious/README.md`. The derived animation resource retains CC BY 4.0; it is not MIT-only because its baker is code.

## Retained Quaternius predator reference

Velociraptor by **Quaternius**, Dinosaur Animated Pack (December 2018).
CC0 1.0 Universal; the original license is in `arca/assets/raptor/LICENSE_QUATERNIUS.txt`.

Author source: <https://quaternius.itch.io/animated-lowpoly-dinosaurs>
Pack page: <https://quaternius.com/packs/animateddinosaurs.html>

The FBX was converted to GLB using Godot 4.5.1. ARCA adjusts scene scale and adds AI, collision and navigation; original clips and materials are preserved.

## Regina inspection asset

**"DinoCrisisCustom - Regina"** by **Otherspectre**.
Source: <https://skfb.ly/pCKMp>.
Licensed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**: <http://creativecommons.org/licenses/by/4.0/>.

The supplied `arca/assets/characters/regina/regina.glb` retains its embedded creator/license metadata and is unchanged. Godot 4.5.1 extracts its embedded textures for import; the separate `arca/character_test.tscn` applies a 180-degree yaw and -0.0112332 m vertical offset to its instance, with no scale, geometry, rig or material edits. No local FBX conversion is claimed. See `docs/REGINA.md` for the imported inventory and limitations. This fan-character credit does not establish rights to underlying third-party characters/IP or verify whether the model was independently created; provenance beyond the supplied credit and metadata remains unverified.

## Regina locomotion experiment

**Universal Animation Library — Standard** by **Quaternius**, **CC0 1.0 Universal**.
Author/pack: <https://quaternius.com/packs/universalanimationlibrary.html>.
Original distribution: <https://quaternius.itch.io/universal-animation-library>.
License: <https://creativecommons.org/publicdomain/zero/1.0/>; full notice retained in `arca/assets/characters/regina/source/LICENSE_CC0.txt`.

Obtained from the free Standard glTF mirror at <https://github.com/J-Ponzo/gltf-universal-animation-library/tree/e24c23cf2a1323488a3faa226ea7ea21f644b73e>. `source/ual_locomotion.glb` retains only `Idle_Loop`, `Walk_Loop`, `Jog_Fwd_Loop` and their donor rig/mannequin, with unused data removed and files repacked. The mannequin is used only for offline generation, not displayed by ARCA. Pinned input/subset hashes and reproducible extraction are in `source/README.md` alongside the asset.

ARCA's derived `locomotion.tres` maps those clips onto the Regina reference rig, preserves its lengths/skin, closes small loop endpoint differences, calibrates constant foot-height offsets and -Z travel, and retimes the jog to 70% playback for the run. Source animation/mannequin data is CC0; the Regina rig/reference transforms retain the Otherspectre **CC BY 4.0** attribution and provenance limits above. The derived `locomotion.tres` asset is not covered by the MIT code license merely because the baker is code. The earlier TPS trial was not used for that isolated three-clip library.

## Regina gameplay animation bake

`arca/assets/characters/regina/gameplay.tres` is generated offline by `arca/assets/characters/regina/bake_gameplay.gd`. Its retargeted TPS poses derive from the already credited Godot Third Person Shooter Demo's CC BY 3.0 `player/model/player.glb`, including combat idle, armed run, directional strafe, jump/fall/landing and aim-center source clips. The baker documents the source mapping and emits derived animation data; the robot donor model is not instantiated at runtime. Gameplay-only modifications include root/pelvis travel separation, preserved gait loops, constant sole-height alignment and short-hop phase retiming. Original donor clips, Regina rig/skin and the separate locomotion proof remain unchanged. The library also includes Regina locomotion poses derived from the credited Quaternius CC0 Universal Animation Library source above. The Regina reference rig retains its separate CC BY 4.0 attribution. This combined derived animation library carries those underlying source attributions and is not made MIT-only by the baker's code license.

## AI development tooling

**hybridindie/godot-mcp** by John Doh / John D Studios, MIT.
Source: <https://github.com/hybridindie/godot-mcp/tree/ba5026d2a34073e8e4b68874cb8b03b691f04636>.
`addons/godot_mcp/` is the unchanged upstream addon at that pinned revision, with its original notice in `addons/godot_mcp/LICENSE`. The matching Python server is installed outside ARCA; see `docs/AI_ENVIRONMENT.md` for the Godot 4.5.1 compatibility decision.

Selected Godot architecture, animation and debugging skill topics adapted from **vl4dt/godot-skills**, copyright (c) 2026 RoboCat, MIT.
Source: <https://github.com/vl4dt/godot-skills/tree/1ae280d35f2cc3931d4d8eb63f4bac82d6acf4a0>.
The focused `.agents/skills/godot-3d-patterns`, `godot-animation-audit` and `godot-debug-regression` adaptations exclude incompatible/incorrect examples and preserve the full upstream notice in `.agents/skills/LICENSE_GODOT_SKILLS.txt`. The upstream package and its overlapping MCP bridge are not installed.

## Regina gameplay hand grip

`source/ual_pistol_grip.glb` is a separate, unchanged-pose subset of the same pinned **Quaternius Universal Animation Library — Standard (CC0)** source: `Pistol_Aim_Neutral`, `Pistol_Aim_Up`, `Pistol_Aim_Down` and their offline donor rig/mannequin. The existing CC0 notice remains in `source/LICENSE_CC0.txt`; hashes/extraction commands are in `source/README.md`. No additional asset service, paid pack or new license was introduced.

`arca/assets/characters/regina/bake_grip.gd` produces `grip.tres`: anatomical/rest-aware right-finger rotations from the neutral pistol pose and a separate additive wrist correction in Regina's reference frame. These are gameplay derivatives, not edits to original clips, rig rests or skin weights. Source animation is CC0; Regina reference transforms retain the Otherspectre **CC BY 4.0** attribution and provenance limits. The calibrated socket/weapon reference scene is original ARCA work and reuses the unchanged primitive handgun geometry.

The gameplay bake maps Quaternius up/down relative to neutral into constant additive right-arm and neck/head rotations. The CC0 source animation and the CC BY 4.0 target-rig attribution apply to these two derivative clips.

## ARCA additions

Fuse, panel, door, divider geometry, the Regina prototype handgun's simple box meshes, mission and ambush logic, documentation and project workflow files are ARCA additions under MIT, as stated in `LICENSE_ARCA.md`. The handgun is original placeholder geometry, not extracted from the TPS robot or represented as final weapon art.
The two short sounds `arca/audio/pickup.wav` and `arca/audio/power.wav` are original synthesized sounds distributed under the same MIT license; they are not extracted from games or third-party sound packs.

The playable mission retains its credited TPS foundation and uses the Ferocious Industries predator above. The Quaternius dinosaur source remains available as a retained reference, not a second gameplay enemy. The separate inspection scene includes the Regina fan model credited above; its underlying provenance has not been independently verified. Neither that model's stated CC license nor ARCA's broader fan-story concept grants rights to Capcom's names or characters.

## Regina gameplay lateral steps

`arca/assets/characters/regina/source/ual2_strafe.glb` contains `Walk_L_Loop` and `Walk_R_Loop` from Quaternius **Universal Animation Library 2** under **CC0 1.0**, with the original notice in `LICENSE_UAL2.txt`. The gameplay library retargets pelvis, spine and leg tracks onto the credited Regina target. The source subset retains the mannequin and original key values. Source pin and extraction steps are in the accompanying source README.
