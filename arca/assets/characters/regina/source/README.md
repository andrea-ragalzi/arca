# Regina locomotion and grip animation source

**Universal Animation Library — Standard**, by **Quaternius**.

- Author's pack/license page: <https://quaternius.com/packs/universalanimationlibrary.html>
- Author's distribution page: <https://quaternius.itch.io/universal-animation-library>
- **CC0 1.0 Universal**: <https://creativecommons.org/publicdomain/zero/1.0/>.
- Full original CC0 notice preserved in `LICENSE_CC0.txt`.

The author's pack page explicitly lists CC0 and permits personal, educational and commercial use. ARCA obtained the Godot glTF files from a public mirror of the free Standard distribution, not the paid Pro/Source editions:

<https://github.com/J-Ponzo/gltf-universal-animation-library/tree/e24c23cf2a1323488a3faa226ea7ea21f644b73e>

The mirror README identifies the author, original itch.io distribution and its 2025-06-10 Standard snapshot. Downloaded on 2026-10-17; no account, paid assets or new runtime dependency was used. The full download remains an ignored local artifact, not an application dependency.

## Preserved inputs and modifications

| Pinned input | SHA-256 |
| --- | --- |
| `glTF/AnimationLibrary_Godot_Standard.gltf` | `0ff075c7ad6855c5c2c37a171592ee8f0d6ab2f58259e2be77a9b63dd8027765` |
| `glTF/AnimationLibrary_Godot_Standard.bin` | `6e65377d81558333c4093dbb144a48fd19019343d82b1a3a7992a98ec0e0543c` |
| Mirror `LICENSE` | `a2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499` |
| ARCA `ual_locomotion.glb` | `ac818ca593dd74f653caf275c7d8487ca72c9f2d5abd16bb2c4284e0546468c5` |
| ARCA `ual_pistol_grip.glb` | `abbbe83522a7ec1e18d5e0c1175140af619b6402b724bb8cb3be429403f36eb1` |

`extract_locomotion.py` retains only **`Idle_Loop`, `Walk_Loop`, `Jog_Fwd_Loop`**, their original 53-joint skin and the small untextured mannequin necessary for a conventional skinned Godot import. It removes unused animation accessors/buffer data, repacks into one self-contained 767,524-byte GLB and adds source/license metadata. It does not change poses or author movement. No other clips are included. The donor mannequin is loaded **only by the offline baker**, never by F6 or F5.

Reproduce the subset with Python 3's standard library, after downloading/verifying the two pinned input files into the same local directory:

```bash
python3 arca/assets/characters/regina/source/extract_locomotion.py /absolute/path/to/AnimationLibrary_Godot_Standard.gltf
```

Import the subset and the unchanged Regina GLB in Godot 4.5.1, then regenerate the derived animation library from the ARCA root:

```bash
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --path . -s res://arca/assets/characters/regina/bake_locomotion.gd
```

Stop play and finish editor imports before generation; do not run a competing editor/importer against an open project. This command intentionally regenerates `../locomotion.tres`, not either source GLB. Resource identifiers may differ between saves; the pose/key data is the reproducible contract.

## Retargeted library

`../bake_locomotion.gd` contains the explicit Regina/UAL map and asset-specific calibration. `../locomotion.tres` contains only derived `idle`, `walk` and `run` clips. Modifications: anatomical/rest-axis mapping, preservation of Regina lengths and reference skin, pelvis-center translation scaled by leg length, small endpoint seam closure, constant per-clip foot-height correction, measured -Z travel on a separate root-motion proxy, and a 0.7 playback retiming for the run. There is no IK, runtime retargeting, root locking, cloth simulation or model replacement.

The **source animation/mannequin data is CC0**; the target rig/reference transforms derive from the **Otherspectre Regina asset credited under CC BY 4.0** in `ATTRIBUTIONS.md`. Retargeting does not remove that character attribution or resolve the underlying character/IP provenance limitation. The animation library is not relicensed as MIT code.

## Gameplay hand grip and vertical aim

`ual_pistol_grip.glb` retains the immutable **`Pistol_Aim_Neutral`**, **`Pistol_Aim_Up`** and **`Pistol_Aim_Down`** clips and the same 53-joint donor mannequin from the pinned Standard inputs (731,108 bytes). It is an offline source only. The optional extractor mode does not change the existing locomotion subset; default extraction was verified byte-identical.

```bash
python3 arca/assets/characters/regina/source/extract_locomotion.py /absolute/path/to/AnimationLibrary_Godot_Standard.gltf --pistol-grip
/home/andrea/Applications/Godot_v4.5.1-stable_linux.x86_64 --headless --audio-driver Dummy --path . -s res://arca/assets/characters/regina/bake_grip.gd
```

Import the new subset first, following the same saved-editor/isolated-import precautions above. `bake_grip.gd` saves only `../grip.tres`: 15 right-finger rotations from the first neutral-pistol frame, converted through anatomical palm frames without copying translations/scales, plus a separate rest-relative additive wrist half-turn. The latter corrects the backward-facing palm while the socket's opposite gun rotation preserves the evaluated barrel basis; it does not freeze the animated wrist. Runtime uses the existing AnimationTree with explicit hand-only filters. Target rests/weights, original clips, the three-clip library and weapon geometry remain unchanged. These derivatives retain the CC0 animation / Regina CC BY 4.0 provenance split described above.

After import, run `bake_gameplay.gd` with the same command and replace the script path. That baker saves `../gameplay.tres` and derives the two vertical aim deltas from up/down relative to neutral, using the existing UAL anatomical map and the 70-degree camera reference. The neutral clip still feeds `bake_grip.gd`.

The locally archived Standard inventory has 46 clips, including pistol poses, but **no backward/side/diagonal locomotion set**. The author's broader library page advertises eight-direction locomotion and separate Standard/Pro/Source tiers; that is not proof that the already obtained free Standard subset contains it. No paid acquisition, directional replacement, invented diagonal clip or new runtime donor was added.

The existing official TPS CC BY 3.0 animation set was inspected and trial-retargeted first. Its mechanical limb chains/proportions and shoulder posture were a poorer fit; none of its motion is included in this final library. See `docs/REGINA.md` for the experiment and root-motion limits.

## UAL2 lateral walks

The offline-only `ual2_strafe.glb` retains `Walk_L_Loop` and `Walk_R_Loop` from the in-place Godot export of [Quaternius Universal Animation Library 2](https://quaternius.com/packs/universalanimationlibrary2.html). The source export and original CC0 notice are pinned to the [tilakverse-assets mirror](https://github.com/tilakpatell/tilakverse-assets/tree/85064399bbdacc0e8cc50807179490314bc4ff1c/quaternius/universal-animation-library-2).

| File | SHA-256 |
| --- | --- |
| `Unreal-Godot/UAL2.glb` | `ad3ae049c7d3d4846133b59dba6218fdabebe05d3aec646caef6665f6c540684` |
| `LICENSE_UAL2.txt` | `d77329b05c4c206e76c83285ecdd1e5f2b3df2350ec80657ebdb5a706a0fc0de` |
| `ual2_strafe.glb` | `737b5c987517237194c9b44714b67f7c2e4dda4e8fbb3df1f49d25a55f6b0201` |

```bash
python3 arca/assets/characters/regina/source/extract_locomotion.py /absolute/path/to/UAL2.glb --strafe
```

Import the subset before running `bake_gameplay.gd`.

## Death and chest hit reactions

`ual_reactions.glb` retains **`Death01`** and **`Hit_Chest`** and the same offline donor mannequin from the pinned Standard inputs above (744,612 bytes). Its SHA-256 is `9bf16e262643112b9b7cdd4f722ce3ba032eaec561b5d84ad2c63d4a0463eedb`.

Verify the glTF and adjacent buffer against the table above, then extract, import and bake with Godot 4.5.1:

```bash
python3 arca/assets/characters/regina/source/extract_locomotion.py /absolute/path/to/AnimationLibrary_Godot_Standard.gltf --reactions
"$HOME/Applications/Godot_v4.5.1-stable_linux.x86_64" --headless --editor --import --path .
"$HOME/Applications/Godot_v4.5.1-stable_linux.x86_64" --headless --audio-driver Dummy --path . -s res://arca/assets/characters/regina/bake_reactions.gd
```

The baker reuses the Standard UAL bone map and scales the death clip's pelvis motion to Regina's leg lengths. The 2.375-second fall retains its authored direction and ends in a held pose. The 0.3-second hit uses local torso and neck rotations relative to the first source pose. The gameplay tree adds these rotations to the live pose while locomotion continues supplying root motion. Both reaction clips live in `../reactions.tres` and contain only skeleton tracks. The CC0 animation and CC BY 4.0 Regina reference-rig attributions apply to the bake.
