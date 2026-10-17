#!/usr/bin/env python3
"""Keep three CC0 UAL clips and their donor rig; no third-party Python packages.

Usage: python3 extract_locomotion.py /path/to/AnimationLibrary_Godot_Standard.gltf
Reads the adjacent .bin; writes ual_locomotion.glb beside this script.
Upstream/mirror pins, hashes and license are documented in README.md.
"""

import copy
import json
from pathlib import Path
import struct
import sys


def extract(source: Path, destination: Path) -> None:
    document = json.loads(source.read_text())
    binary = (source.parent / document["buffers"][0]["uri"]).read_bytes()
    names = {"Idle_Loop", "Walk_Loop", "Jog_Fwd_Loop"}
    document["animations"] = [a for a in document["animations"] if a["name"] in names]
    if {a["name"] for a in document["animations"]} != names:
        raise ValueError("Expected idle, walk and jog clips are missing")

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
        "source": "https://quaternius.com/packs/universalanimationlibrary.html",
        "modification": "ARCA: retained only Idle_Loop, Walk_Loop, Jog_Fwd_Loop; repacked as GLB",
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
    print(f"Wrote {destination}: {length} bytes, three clips")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    extract(Path(sys.argv[1]), Path(__file__).with_name("ual_locomotion.glb"))
