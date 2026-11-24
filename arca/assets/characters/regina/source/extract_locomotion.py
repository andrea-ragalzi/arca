#!/usr/bin/env python3
"""Extract immutable CC0 UAL subsets; no third-party Python packages.

Usage: python3 extract_locomotion.py /path/to/AnimationLibrary_Godot_Standard.gltf [--pistol-grip | --reactions]
       python3 extract_locomotion.py /path/to/UAL2.glb --strafe
Reads the adjacent .bin; writes ual_locomotion.glb (three clips) or
ual_pistol_grip.glb (neutral, up and down pistol poses) or
ual_reactions.glb (death and chest hit) beside this script.
The UAL2 option reads a GLB and writes its two lateral walks to ual2_strafe.glb.
Upstream/mirror pins, hashes and license are documented in README.md.
"""

import copy
import json
from pathlib import Path
import struct
import sys


def extract(
    source: Path,
    destination: Path,
    clips: tuple[str, ...] = ("Idle_Loop", "Walk_Loop", "Jog_Fwd_Loop"),
    pack: str = "universalanimationlibrary",
) -> None:
    if source.suffix.lower() == ".glb":
        glb = source.read_bytes()
        magic, version, total, json_size, json_type = struct.unpack_from("<5I", glb)
        data_offset = 20 + json_size
        data_size, data_type = struct.unpack_from("<2I", glb, data_offset)
        if (magic, version, total, json_type, data_type) != (0x46546C67, 2, len(glb), 0x4E4F534A, 0x004E4942):
            raise ValueError("Expected a GLB 2.0 with JSON and binary chunks")
        document = json.loads(glb[20:data_offset])
        binary = glb[data_offset + 8:data_offset + 8 + data_size]
    else:
        document = json.loads(source.read_text())
        binary = (source.parent / document["buffers"][0]["uri"]).read_bytes()
    names = set(clips)
    document["animations"] = [a for a in document["animations"] if a["name"] in names]
    if {a["name"] for a in document["animations"]} != names:
        raise ValueError(f"Expected source clips are missing: {sorted(names)}")

    # Keep the small skinned mannequin so Godot can reconstruct the donor skin.
    # It is never instantiated by the F6 viewer or the mission.
    references = []
    for animation in document["animations"]:
        references.extend((s, k) for s in animation["samplers"] for k in ("input", "output"))
    references.extend((skin, "inverseBindMatrices") for skin in document["skins"])
    for mesh in document["meshes"]:
        for primitive in mesh["primitives"]:
            references.append((primitive, "indices"))
            references.extend((primitive["attributes"], k) for k in primitive["attributes"])

    accessors = sorted({owner[key] for owner, key in references})
    remap = {old: new for new, old in enumerate(accessors)}
    for owner, key in references:
        owner[key] = remap[owner[key]]
    original_accessors = document["accessors"]
    original_views = document["bufferViews"]
    document["accessors"] = []
    document["bufferViews"] = []
    payload = bytearray()
    view_remap = {}
    for old in accessors:
        accessor = copy.deepcopy(original_accessors[old])
        view_id = accessor["bufferView"]
        if view_id not in view_remap:
            view = copy.deepcopy(original_views[view_id])
            payload.extend(b"\0" * (-len(payload) % 4))
            offset = view.get("byteOffset", 0)
            data = binary[offset:offset + view["byteLength"]]
            view["buffer"] = 0
            view["byteOffset"] = len(payload)
            payload.extend(data)
            view_remap[view_id] = len(document["bufferViews"])
            document["bufferViews"].append(view)
        accessor["bufferView"] = view_remap[view_id]
        document["accessors"].append(accessor)
    document["buffers"] = [{"byteLength": len(payload)}]
    document["asset"]["extras"] = {
        "author": "Quaternius",
        "license": "CC0-1.0",
        "source": f"https://quaternius.com/packs/{pack}.html",
        "modification": f"ARCA: retained only {', '.join(clips)}; repacked as GLB",
    }
    header = json.dumps(document, separators=(",", ":")).encode()
    header += b" " * (-len(header) % 4)
    payload.extend(b"\0" * (-len(payload) % 4))
    length = 12 + 8 + len(header) + 8 + len(payload)
    destination.write_bytes(
        struct.pack("<III", 0x46546C67, 2, length)
        + struct.pack("<II", len(header), 0x4E4F534A) + header
        + struct.pack("<II", len(payload), 0x004E4942) + payload
    )
    print(f"Wrote {destination}: {length} bytes, {len(clips)} clips")


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[2] == "--strafe":
        extract(Path(sys.argv[1]), Path(__file__).with_name("ual2_strafe.glb"),
                ("Walk_L_Loop", "Walk_R_Loop"), "universalanimationlibrary2")
    elif len(sys.argv) == 3 and sys.argv[2] == "--pistol-grip":
        extract(Path(sys.argv[1]), Path(__file__).with_name("ual_pistol_grip.glb"),
                ("Pistol_Aim_Neutral", "Pistol_Aim_Up", "Pistol_Aim_Down"))
    elif len(sys.argv) == 3 and sys.argv[2] == "--reactions":
        extract(Path(sys.argv[1]), Path(__file__).with_name("ual_reactions.glb"),
                ("Death01", "Hit_Chest"))
    elif len(sys.argv) == 2:
        extract(Path(sys.argv[1]), Path(__file__).with_name("ual_locomotion.glb"))
    else:
        raise SystemExit(__doc__)
