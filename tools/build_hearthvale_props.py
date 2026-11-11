#!/usr/bin/env python3
"""Build the eight Hearthvale prop GLBs.

Each file is glTF 2.0 binary: 1 unit = 1 metre, Y-up, origin at the base
centre, flat named materials (base colour only), well under 1,300 triangles.

  assets/models/props/hearthvale/hearthvale_<prop_id>.glb

The fence segment is 2.0 m along local X. The crop patch is 2.0 m by 2.0 m.
"""

from __future__ import annotations

import json
import math
import struct
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "assets" / "models" / "props" / "hearthvale"


def _cross(a, b):
    return (
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    )


def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def _mul(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def _norm(a):
    length = math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]) or 1.0
    return (a[0] / length, a[1] / length, a[2] / length)


class MeshBuilder:
    def __init__(self) -> None:
        self.prims: dict[str, dict] = {}

    def _prim(self, material: str) -> dict:
        prim = self.prims.get(material)
        if prim is None:
            prim = {"pos": [], "nrm": [], "idx": []}
            self.prims[material] = prim
        return prim

    def add(self, material: str, a, b, c) -> None:
        normal = _norm(_cross(_sub(b, a), _sub(c, a)))
        if normal[0] == 0.0 and normal[1] == 0.0 and normal[2] == 0.0:
            normal = (0.0, 1.0, 0.0)
        prim = self._prim(material)
        start = len(prim["pos"])
        for vertex in (a, b, c):
            prim["pos"].append(vertex)
            prim["nrm"].append(normal)
        prim["idx"].extend((start, start + 1, start + 2))

    def add_quad(self, material: str, p0, p1, p2, p3) -> None:
        # p0-p1-p2-p3 is CCW when viewed from outside.
        self.add(material, p0, p1, p2)
        self.add(material, p0, p2, p3)

    def box(self, material: str, center, size) -> None:
        cx, cy, cz = center
        hx, hy, hz = size[0] * 0.5, size[1] * 0.5, size[2] * 0.5
        corners = []
        for z in (-hz, hz):
            for y in (-hy, hy):
                for x in (-hx, hx):
                    corners.append((cx + x, cy + y, cz + z))
        # corners index: x + y*2 + z*4, x/y/z in {0,1} where 0 is negative.
        def c(x, y, z):
            return corners[x + y * 2 + z * 4]

        # +Y
        self.add_quad(material, c(0, 1, 0), c(0, 1, 1), c(1, 1, 1), c(1, 1, 0))
        # -Y
        self.add_quad(material, c(0, 0, 1), c(0, 0, 0), c(1, 0, 0), c(1, 0, 1))
        # +X
        self.add_quad(material, c(1, 0, 0), c(1, 1, 0), c(1, 1, 1), c(1, 0, 1))
        # -X
        self.add_quad(material, c(0, 0, 1), c(0, 1, 1), c(0, 1, 0), c(0, 0, 0))
        # +Z
        self.add_quad(material, c(0, 0, 1), c(1, 0, 1), c(1, 1, 1), c(0, 1, 1))
        # -Z
        self.add_quad(material, c(1, 0, 0), c(0, 0, 0), c(0, 1, 0), c(1, 1, 0))

    def cylinder(self, material: str, y0: float, y1: float, r0: float, r1: float, sides: int = 6) -> None:
        def ring(y, radius, i):
            angle = (i / sides) * math.tau
            return (math.cos(angle) * radius, y, math.sin(angle) * radius)

        for i in range(sides):
            a0, a1 = ring(y0, r0, i), ring(y0, r0, i + 1)
            b0, b1 = ring(y1, r1, i), ring(y1, r1, i + 1)
            self.add_quad(material, a0, b0, b1, a1)
        top = (0.0, y1, 0.0)
        bottom = (0.0, y0, 0.0)
        for i in range(sides):
            self.add(material, ring(y1, r1, i), top, ring(y1, r1, i + 1))
            self.add(material, ring(y0, r0, i + 1), bottom, ring(y0, r0, i))

    def sphere(self, material: str, center, radius: float, slices: int = 8, stacks: int = 5, scale=(1.0, 1.0, 1.0)) -> None:
        def point(stack, slc):
            v = stack / stacks
            u = slc / slices
            theta = v * math.pi
            phi = u * math.tau
            local = (
                math.sin(theta) * math.cos(phi) * radius * scale[0],
                math.cos(theta) * radius * scale[1],
                math.sin(theta) * math.sin(phi) * radius * scale[2],
            )
            return _add(center, local)

        for stack in range(stacks):
            for slc in range(slices):
                p00 = point(stack, slc)
                p10 = point(stack + 1, slc)
                p11 = point(stack + 1, slc + 1)
                p01 = point(stack, slc + 1)
                if stack != 0:
                    self.add(material, p00, p10, p01)
                if stack != stacks - 1:
                    self.add(material, p01, p10, p11)

    def tris(self) -> int:
        return sum(len(prim["idx"]) // 3 for prim in self.prims.values())


def write_glb(path: Path, name: str, colors: dict[str, tuple], builder: MeshBuilder) -> None:
    blob = bytearray()
    views = []
    accessors = []
    primitives = []
    materials = []
    material_index = {mat: i for i, mat in enumerate(builder.prims)}
    for mat_name, rgba in colors.items():
        if mat_name not in material_index:
            continue
        materials.append(
            {
                "name": mat_name,
                "pbrMetallicRoughness": {
                    "baseColorFactor": [rgba[0], rgba[1], rgba[2], 1.0],
                    "metallicFactor": 0.0,
                    "roughnessFactor": 1.0,
                },
            }
        )
    # Rebuild material list in prim order so indices match.
    materials = []
    for mat_name in builder.prims:
        rgba = colors[mat_name]
        materials.append(
            {
                "name": mat_name,
                "pbrMetallicRoughness": {
                    "baseColorFactor": [rgba[0], rgba[1], rgba[2], 1.0],
                    "metallicFactor": 0.0,
                    "roughnessFactor": 1.0,
                },
            }
        )

    for mat_i, (mat_name, prim) in enumerate(builder.prims.items()):
        pos = prim["pos"]
        nrm = prim["nrm"]
        idx = prim["idx"]
        pos_bytes = b"".join(struct.pack("<3f", *p) for p in pos)
        nrm_bytes = b"".join(struct.pack("<3f", *n) for n in nrm)
        idx_bytes = b"".join(struct.pack("<H", i) for i in idx)
        if len(idx_bytes) % 4:
            idx_bytes += b"\x00" * (4 - len(idx_bytes) % 4)

        def push(data: bytes, target: int) -> int:
            while len(blob) % 4:
                blob.append(0)
            offset = len(blob)
            blob.extend(data)
            views.append({"buffer": 0, "byteOffset": offset, "byteLength": len(data), "target": target})
            return len(views) - 1

        pos_view = push(pos_bytes, 34962)
        nrm_view = push(nrm_bytes, 34962)
        idx_view = push(idx_bytes, 34963)
        xs = [p[0] for p in pos]
        ys = [p[1] for p in pos]
        zs = [p[2] for p in pos]
        pos_acc = len(accessors)
        accessors.append(
            {
                "bufferView": pos_view,
                "componentType": 5126,
                "count": len(pos),
                "type": "VEC3",
                "min": [min(xs), min(ys), min(zs)],
                "max": [max(xs), max(ys), max(zs)],
            }
        )
        nrm_acc = len(accessors)
        accessors.append(
            {
                "bufferView": nrm_view,
                "componentType": 5126,
                "count": len(nrm),
                "type": "VEC3",
            }
        )
        idx_acc = len(accessors)
        accessors.append(
            {
                "bufferView": idx_view,
                "componentType": 5123,
                "count": len(idx),
                "type": "SCALAR",
            }
        )
        primitives.append(
            {
                "attributes": {"POSITION": pos_acc, "NORMAL": nrm_acc},
                "indices": idx_acc,
                "material": mat_i,
            }
        )

    gltf = {
        "asset": {"version": "2.0", "generator": "lantern-hearthvale-props"},
        "scene": 0,
        "scenes": [{"nodes": [0], "name": name}],
        "nodes": [{"name": name, "mesh": 0}],
        "meshes": [{"name": name, "primitives": primitives}],
        "materials": materials,
        "accessors": accessors,
        "bufferViews": views,
        "buffers": [{"byteLength": len(blob)}],
    }
    json_bytes = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    while len(json_bytes) % 4:
        json_bytes += b" "
    while len(blob) % 4:
        blob.append(0)
    total = 12 + 8 + len(json_bytes) + 8 + len(blob)
    out = bytearray()
    out += struct.pack("<III", 0x46546C67, 2, total)
    out += struct.pack("<II", len(json_bytes), 0x4E4F534A)
    out += json_bytes
    out += struct.pack("<II", len(blob), 0x004E4942)
    out += blob
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(out)
    print(f"{path.name:28} tris={builder.tris():4d} bytes={len(out)}")


def build_fence() -> tuple[MeshBuilder, dict]:
    mesh = MeshBuilder()
    wood = (0.55, 0.36, 0.20)
    mesh.box("Wood", (-0.92, 0.52, 0.0), (0.10, 1.04, 0.10))
    mesh.box("Wood", (0.92, 0.52, 0.0), (0.10, 1.04, 0.10))
    mesh.box("Wood", (0.0, 0.40, 0.0), (1.84, 0.07, 0.05))
    mesh.box("Wood", (0.0, 0.78, 0.0), (1.84, 0.07, 0.05))
    return mesh, {"Wood": wood}


def build_hay() -> tuple[MeshBuilder, dict]:
    mesh = MeshBuilder()
    mesh.box("Hay", (0.0, 0.32, 0.0), (1.25, 0.64, 0.86))
    mesh.box("Band", (0.0, 0.32, 0.0), (1.28, 0.10, 0.90))
    mesh.box("Band", (0.0, 0.32, 0.0), (0.10, 0.68, 0.90))
    return mesh, {"Hay": (0.86, 0.70, 0.28), "Band": (0.42, 0.28, 0.16)}


def build_oak() -> tuple[MeshBuilder, dict]:
    mesh = MeshBuilder()
    mesh.cylinder("Bark", 0.0, 2.15, 0.34, 0.20, 7)
    mesh.sphere("Leaves", (0.0, 3.15, 0.0), 1.35, 8, 5, (1.08, 0.82, 1.02))
    mesh.sphere("Leaves", (-0.7, 2.7, 0.35), 0.75, 7, 4)
    mesh.sphere("Leaves", (0.65, 2.85, -0.3), 0.7, 7, 4)
    return mesh, {"Bark": (0.40, 0.26, 0.15), "Leaves": (0.34, 0.62, 0.26)}


def build_fruit() -> tuple[MeshBuilder, dict]:
    mesh = MeshBuilder()
    mesh.cylinder("Bark", 0.0, 1.55, 0.26, 0.16, 6)
    mesh.sphere("Leaves", (0.0, 2.35, 0.0), 1.05, 8, 5, (1.05, 0.9, 1.05))
    fruits = (
        (0.45, 2.15, 0.35),
        (-0.4, 2.3, 0.4),
        (0.15, 2.7, -0.45),
        (-0.55, 1.9, -0.15),
        (0.6, 1.85, -0.2),
        (0.0, 2.05, 0.65),
    )
    for center in fruits:
        mesh.sphere("Fruit", center, 0.10, 5, 3)
    return mesh, {
        "Bark": (0.45, 0.30, 0.18),
        "Leaves": (0.42, 0.66, 0.28),
        "Fruit": (0.86, 0.28, 0.20),
    }


def build_flowers() -> tuple[MeshBuilder, dict]:
    mesh = MeshBuilder()
    spots = (
        (0.0, 0.0, 0.0),
        (0.22, 0.0, 0.12),
        (-0.18, 0.0, 0.16),
        (0.08, 0.0, -0.22),
        (-0.2, 0.0, -0.14),
        (0.28, 0.0, -0.08),
        (-0.05, 0.0, 0.26),
    )
    for i, (x, _, z) in enumerate(spots):
        height = 0.34 + (i % 3) * 0.06
        mesh.cylinder("Stem", 0.0, height, 0.015, 0.012, 4)
        # Shift the stem off the origin by moving its vertices is harder with cylinder().
        # Build the blossom at the spot; stems stay centred then we add a thin box instead.
    mesh.prims.clear()
    for i, (x, _, z) in enumerate(spots):
        height = 0.32 + (i % 3) * 0.07
        mesh.box("Stem", (x, height * 0.5, z), (0.03, height, 0.03))
        petal = "Petal" if i % 2 == 0 else "PetalWarm"
        mesh.sphere(petal, (x, height + 0.06, z), 0.09, 6, 3, (1.0, 0.7, 1.0))
    return mesh, {
        "Stem": (0.28, 0.46, 0.20),
        "Petal": (0.93, 0.55, 0.62),
        "PetalWarm": (0.95, 0.78, 0.35),
    }


def build_bush() -> tuple[MeshBuilder, dict]:
    mesh = MeshBuilder()
    mesh.sphere("Leaves", (0.0, 0.42, 0.0), 0.55, 8, 4, (1.25, 0.75, 1.15))
    mesh.sphere("Leaves", (-0.28, 0.32, 0.12), 0.38, 6, 3, (1.1, 0.8, 1.0))
    mesh.sphere("Leaves", (0.26, 0.34, -0.1), 0.36, 6, 3, (1.0, 0.85, 1.15))
    return mesh, {"Leaves": (0.28, 0.52, 0.24)}


def build_rock() -> tuple[MeshBuilder, dict]:
    mesh = MeshBuilder()
    mesh.sphere("Stone", (0.0, 0.32, 0.0), 0.48, 7, 4, (1.35, 0.72, 1.05))
    mesh.sphere("Stone", (0.18, 0.28, 0.12), 0.28, 6, 3, (1.1, 0.7, 0.9))
    return mesh, {"Stone": (0.62, 0.60, 0.56)}


def build_crop() -> tuple[MeshBuilder, dict]:
    mesh = MeshBuilder()
    mesh.box("Soil", (0.0, 0.03, 0.0), (2.0, 0.06, 2.0))
    rows = 4
    cols = 5
    for row in range(rows):
        for col in range(cols):
            x = -0.7 + col * 0.35
            z = -0.6 + row * 0.4
            height = 0.26 + ((row + col) % 3) * 0.05
            mesh.box("Crop", (x, 0.06 + height * 0.5, z), (0.07, height, 0.07))
    return mesh, {"Soil": (0.45, 0.32, 0.18), "Crop": (0.52, 0.70, 0.22)}


def main() -> None:
    specs = {
        "hearthvale_fence.glb": ("Fence", build_fence),
        "hearthvale_hay_bale.glb": ("HayBale", build_hay),
        "hearthvale_oak.glb": ("Oak", build_oak),
        "hearthvale_fruit_tree.glb": ("FruitTree", build_fruit),
        "hearthvale_flower_clump.glb": ("FlowerClump", build_flowers),
        "hearthvale_bush.glb": ("Bush", build_bush),
        "hearthvale_rock.glb": ("Rock", build_rock),
        "hearthvale_crop_patch.glb": ("CropPatch", build_crop),
    }
    for filename, (name, builder_fn) in specs.items():
        mesh, colors = builder_fn()
        tris = mesh.tris()
        if tris >= 1300:
            raise SystemExit(f"{filename} has {tris} tris")
        write_glb(OUT / filename, name, colors, mesh)


if __name__ == "__main__":
    main()
