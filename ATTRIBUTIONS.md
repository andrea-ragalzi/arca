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

## Animated predator

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

ARCA's derived `locomotion.tres` maps those clips onto the Regina reference rig, preserves its lengths/skin, closes small loop endpoint differences, calibrates constant foot-height offsets and -Z travel, and retimes the jog to 70% playback for the run. Source animation/mannequin data is CC0; the Regina rig/reference transforms retain the Otherspectre **CC BY 4.0** attribution and provenance limits above. The derived animation asset is not covered by the MIT code license merely because the baker is code. The previously credited TPS CC BY 3.0 set was inspected/trialed first but is not used in the final Regina library.

## ARCA additions

Fuse, panel, door, divider geometry, mission and ambush logic, documentation and project workflow files are ARCA additions under MIT, as stated in `LICENSE_ARCA.md`.
The two short sounds `arca/audio/pickup.wav` and `arca/audio/power.wav` are original synthesized sounds distributed under the same MIT license; they are not extracted from games or third-party sound packs.

The playable mission retains its credited TPS placeholder and Quaternius predator. The separate inspection scene includes the Regina fan model credited above; its underlying provenance has not been independently verified. Neither that model's stated CC license nor ARCA's broader fan-story concept grants rights to Capcom's names or characters.
