# Wellstone landmark

A ring of standing stones with hidden tech seams and a central basin — a relay node in LOAM's network, disguised as a sacred circle. Two GLBs share the same mesh and the same material names; only `WS_Seam` and `WS_Core` change. 1 unit = 1 m, Y-up, origin at the base centre of the ring. Landmark budget is 4k triangles (not the 1.5k prop cap).

## Assets

| File | What it is | Tris | Size (m, X × Y × H) |
|---|---|---:|---|
| `wellstone_dormant.glb` | Standing-stone ring with hidden tech seams, dim / dormant state. ~5 m across. | 752 | 4.57 × 4.43 × 3.52 |
| `wellstone_restored.glb` | Same mesh; cyan seams and a warm gold basin core, emissive. | 752 | 4.57 × 4.43 × 3.52 |

Master blend: `wellstone.blend` (both states).

How to use: instance `wellstone_dormant.glb` when the node is unlit, and swap to `wellstone_restored.glb` when the player mends it (cyan seams, warm gold core). Because the material names match, a shader can also drive the state in-engine if you prefer a single mesh.

The opening in the middle is a shallow basin, not a hole through the world. The head stone (the tallest) sits on the +X side of the ring.

## Weaknesses

- The menhirs are tapered boxes with a little noise, not carved megaliths; they read as a circle from the high camera, but they will look simple up close.
- Seams are thin inlaid tubes on the inward faces, plus a rim around the basin and four buried spokes. They are readable, not a dense circuit pattern.
- There is a small fallen fragment, but no ribbons, offerings or grass inside the ring — those would be scatter props.
- The restored gold core is a flat disc of emission, not a volume glow.
