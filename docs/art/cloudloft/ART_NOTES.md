# Cloudloft Highlands prop kit

Low-poly highland props: wind-bent pines (foliage swept leeward, not stacked cones), slate cliffs, a cairn, heather, a tileable rope-bridge segment, and a Weatherspire. 1 unit = 1 m, Y-up glTF, origin at the base centre. Glowing parts (wind-crystals, the spire seam and crystal) are emissive.

## Assets

| File | What it is | Tris | Size (m, X × Y × H) |
|---|---|---:|---|
| `cloudloft_pine_bent.glb` | Wind-bent pine, foliage swept leeward, ~6 m. Not a stacked cone. | 1100 | 3.12 × 1.39 × 5.95 |
| `cloudloft_pine_young.glb` | Younger wind-bent pine, ~4.2 m. | 1100 | 2.07 × 1.18 × 4.26 |
| `cloudloft_cliff_rock.glb` | Chunky slate outcrop with a snow cap. | 100 | 1.92 × 1.51 × 1.28 |
| `cloudloft_cliff_slab.glb` | Longer terrace/cliff slab with a snow lip, for lining a slope. | 24 | 2.42 × 0.73 × 1.19 |
| `cloudloft_cairn.glb` | Stacked slate cairn with an emissive wind-crystal on top. | 120 | 0.49 × 0.35 × 1.08 |
| `cloudloft_heather.glb` | Heather clump, mauve mounds. | 156 | 0.88 × 0.69 × 0.38 |
| `cloudloft_rope_bridge.glb` | 3 m rope-bridge segment. Post on the -X end only; tile every 3.0 m along X. Walkway at 1.1 m. | 336 | 3.07 × 0.64 × 1.57 |
| `cloudloft_weatherspire.glb` | Stone weather-tower with a bell, a hidden tech seam and an emissive crystal spire, ~6.5 m. | 352 | 1.70 × 1.70 × 6.45 |

Master blend: `cloudloft_kit.blend`.

The rope-bridge segment is 3 m long with a post on the **-X** end only. Tile every 3.0 m along local X, origin to origin. The walkway sits at 1.1 m; the post goes to the ground so a segment can rest on a cliff edge. Mid-span copies will have a support post every 3 m.

The Weatherspire is a placeable tower (~6.5 m) with a bell in the belfry, a hidden tech seam, and an emissive wind-crystal on top. It is a kit prop, not a separate landmark file.

Material names: `CL_Bark`, `CL_Pine`, `CL_PineShadow`, `CL_Slate`, `CL_SlateDark`, `CL_Cliff`, `CL_Snow`, `CL_Crystal`, `CL_CrystalCore`, `CL_Heather`, `CL_HeatherDark`, `CL_Stem`, `CL_Wood`, `CL_WoodDark`, `CL_Rope`, `CL_Metal`, `CL_Bell`, `CL_Grass`, `CL_Seam`.

## Weaknesses

- The pines are branched and wind-swept, but the foliage is still clustered ico-fans, not needle-level detail.
- The cliff slab is a fairly regular box with a little noise; it reads as a terrace block, not a unique crag.
- The rope bridge has a slightly sagging rope and one short plank, but the planks are simple boxes.
- The Weatherspire bell is a small spun shape, not a hero asset, and the belfry is an open post-and-ring rather than a carved lantern house.
