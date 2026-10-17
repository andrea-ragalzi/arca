# Regina locomotion animation source

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

The existing official TPS CC BY 3.0 animation set was inspected and trial-retargeted first. Its mechanical limb chains/proportions and shoulder posture were a poorer fit; none of its motion is included in this final library. See `docs/REGINA.md` for the experiment and root-motion limits.
