> **Repo naming (2026-11-11).** The kit files in this folder follow the repo naming: `hearthvale_<prop>.glb`, `mood-hearthvale.png` and `contact-sheet.png`.
> The other biome boards are in `../glimmerwood/mood-glimmerwood.png`, `../saltglass/mood-saltglass.png`, `../cloudloft/mood-cloudloft.png` and `../greying/mood-greying.png`.
> The originals (`glb/hv_*.glb`, `../moodboards/`, `../renders/`) are untouched. The renamed GLBs are byte-identical copies, re-imported and checked.

# Lantern / Veyla art pack — notes

These assets are for *The Lantern Below* (Lantern / Nestkin), a cosy Godot 4 game with a high, angled follow camera. The style target is Genshin-like cel shading, but the shipped `.glb` files use simple coloured Principled materials so they import cleanly. Cel ramps and inverted-hull outlines are applied only in the Blender preview renders.

## Scale and export

- 1 Blender unit = 1 metre
- glTF export uses the exporter defaults (Y-up)
- Each prop's origin is at the **base centre** (ground contact, XY midpoint)
- Transforms are applied
- Re-imported in Blender: every kit `.glb` came back with the origin and base at world zero, and no extra cameras or lights

Godot itself was not on this machine, so imports have not been tested in the engine. The GLBs are vanilla glTF 2.0 with named base-colour materials.

## Hearthvale prop kit

| File | What it is | Tris | Size (m, XYZ) |
|---|---|---:|---|
| `hearthvale_fence_segment.glb` | Fence, 3 rails, post on the **-X** end only | 72 | 2.08 × 0.13 × 1.22 |
| `hearthvale_hay_bale.glb` | Round bale with twine bands | 320 | 0.96 × 0.76 × 0.95 |
| `hearthvale_oak.glb` | Broad oak, darker underside | 628 | 4.52 × 3.67 × 4.58 |
| `hearthvale_fruit_tree.glb` | Smaller orchard tree, a few apples | 608 | 2.53 × 2.20 × 3.39 |
| `hearthvale_flower_clump.glb` | Mixed wildflowers on a small mound | 1052 | 0.63 × 0.52 × 0.51 |
| `hearthvale_bush.glb` | Round leafy bush | 500 | 1.48 × 1.26 × 1.17 |
| `hearthvale_rock.glb` | River stone with a moss cap | 100 | 0.81 × 0.70 × 0.60 |
| `hearthvale_crop_patch.glb` | 2 m wheat tile with a thin soil base | 1236 | 2.06 × 2.18 × 1.51 |

All are under the ~1.5k triangle cap.

### Tiling

- **Fence:** place copies every **2.0 m** along local X, origin to origin. The post sits 1 m to the left of the origin; the rails run to +1 m so the next post covers the join. The mesh itself is 2.08 m long because the post cap overhangs slightly.
- **Crop patch:** a 2 × 2 m field tile (the soil base is a little ragged, so the bounding box is ~2.06 × 2.18 m). Origin at the underside centre. The wheat stands about 1.5 m tall.

### Materials

Flat, named, Godot-friendly: `HV_Wood`, `HV_WoodDark`, `HV_Bark`, `HV_Leaf`, `HV_LeafShadow`, `HV_Hay`, `HV_HayShadow`, `HV_Twine`, `HV_Stone`, `HV_Moss`, `HV_Wheat`, `HV_WheatGreen`, `HV_Soil`, `HV_FlowerYellow`, `HV_FlowerPink`, `HV_FlowerWhite`, `HV_FlowerLavender`, `HV_Fruit`, `HV_Stem`.

No UVs (solid colours only). Cel shading should be a Godot shader that keys off these base colours, or vertex lighting, rather than anything baked into the GLB.

### Masters

- `hearthvale/hearthvale_kit.blend` — editable meshes, Principled materials, props laid out as on the contact sheet
- `hearthvale/hearthvale_kit_studio.blend` — the cel + outline studio used for the contact render (do not export from this one)
- `manifest.json` (repo naming) and `verify_report.json`; the original kit manifest is kept as `manifest_original_hv.json` — triangle counts and re-import checks

## Mood boards

One PNG per biome, 1600×900, rendered in EEVEE from a high, game-like camera with palette swatches and a short lore line on the sheet. These are blockout concept sheets, not final art.

- Hearthvale: farmland, cottage, kit props, a Wellstone on the far knoll (the too-round hill is a hint at a buried habitat dome)
- Glimmerwood: twilight canopy, glowcaps, copper vein, lantern-moths, a distant Wellstone
- Saltglass Shallows: sand, glass shards, tidepool, stilt houses, a crooked lighthouse with a lit lamp
- Cloudloft Highlands: terraces, wind-bent pines, cairn and wind-crystal, waterfall, cliffs
- The Greying: ashen flats, dead trees, a perfectly straight survey edge with a thin living strip, a dormant tech stub, one brave flower

## Weaknesses (honest)

- Cel shading in the previews is softer than real Genshin: two-tone ramps via EEVEE ShaderToRGB, no custom lighting normals, and the hull outlines are thin. The GLBs themselves are unshaded base colour.
- The fruit tree's apples sit under the canopy and barely read from the high camera.
- Wheat is still a bit sparse; heads read, but it is not a lush field.
- Glimmerwood trees are simple lollipop canopies; the moths are glowing motes, not winged insects; glowcaps are stylised discs more than gilled mushrooms.
- Saltglass "glass" is opaque pastel, not transmissive. The sea is a hard-edged plane. The lighthouse lean is subtle from this angle, and the lamp just makes it into frame.
- Cloudloft's Weatherspire and hanging valley-clouds didn't really make it into the shot; the pines are stacked cones.
- The Greying's living edge still reads a little like a path because of perspective, even though it is a narrow strip along the survey rail.
- The Hearthvale cottage, hedgerow and Wellstone are mood-board blockouts only — they are not kit meshes.


## Hearthvale extras (ground cover and water edges)

Contact sheet: `contact-sheet-extras.png`. Master blend: `hearthvale_extras.blend`.
These sit alongside the original kit props and use the same scale, Y-up glTF, and base-centre origin.

| File | What it is | Tris | Size (m, X × Y × H) |
|---|---|---:|---|
| `hearthvale_grass_clump_small.glb` | Small grass tuft, ~0.22 m, for tight scatter. | 116 | 0.22 × 0.24 × 0.23 |
| `hearthvale_grass_clump.glb` | Medium grass clump, ~0.38 m, general pasture scatter. | 152 | 0.27 × 0.27 × 0.39 |
| `hearthvale_grass_clump_tall.glb` | Taller, slightly windswept grass clump, ~0.62 m. | 152 | 0.55 × 0.49 × 0.60 |
| `hearthvale_ground_cover.glb` | Low ~1.1 m patch of clover and tiny flowers, for ground scatter. | 724 | 1.12 × 0.91 × 0.24 |
| `hearthvale_bank_straight.glb` | 2 m stream bank, water lip on +Y. Tile every 2.0 m along local X. Water surface meets the lip at 0.05 m. | 236 | 2.00 × 1.01 × 0.53 |
| `hearthvale_bank_curve.glb` | 90° bank corner, inner radius 1.0 m. Four pieces make a ~2 m pond around a water tile. | 310 | 2.00 × 2.00 × 0.54 |
| `hearthvale_water_tile.glb` | 2 x 2 m water plane tile, 0.05 m thick, slightly emissive teal. Tile every 2.0 m in X and Y. | 12 | 2.00 × 2.00 × 0.05 |
| `hearthvale_stepping_stones.glb` | A short crossing of four flat river stones with a little moss. Sits in the water tile. | 120 | 1.38 × 0.47 × 0.11 |

### Tiling

- **Grass clumps** and **ground cover** are scatter props. Origin at the ground contact.
- **Straight bank:** 2 m long, post-style tiling every **2.0 m** along local X, origin to origin. The water lip is on the **+Y** side and meets the water tile at **0.05 m**. Land is on −Y and rises to about 0.33 m.
- **Curved bank:** a 90° corner with an inner radius of **1.0 m** (the water lip). Four pieces make a pond about 2 m across. Place each piece so the inner arc hugs the water.
- **Water tile:** a **2 × 2 m** plane, 0.05 m thick. Tile every 2.0 m in X and Y, origin to origin. Slightly emissive teal so it reads from the high camera; not transmissive.
- **Stepping stones:** a fixed cluster of four stones. Sit them in the water tile; they stand a little above the 0.05 m surface.

### Extra materials

`HV_Grass`, `HV_GrassShadow`, `HV_Pasture`, `HV_Clover`, `HV_CloverDark`, `HV_Mud`, `HV_StoneDark`, `HV_Water`, plus the existing `HV_Soil`, `HV_Stone`, `HV_Moss`, `HV_Stem`, `HV_FlowerYellow`, `HV_FlowerPink`, `HV_FlowerWhite`, `HV_Leaf`.

## Extras weaknesses

- Grass blades are simple tapered boxes, not individual blades of grass, so a clump can look a little like a tuft of cards from some angles.
- Clover is three rounded lobes, not a veined trifoliate leaf, and the flowers are small ico heads rather than the petal flowers in `hearthvale_flower_clump`.
- The banks are a clean extruded profile; the curve is a regular 90° arc, not an irregular stream cut.
- A square water tile inside a four-piece circular pond will either show corners or leave small gaps.
- The water is a flat opaque teal plane with a hint of emission, not refractive or animated.
- The stepping stones are a fixed cluster, not loose individual stones.

## Repo paths

Props live in `assets/models/props/hearthvale/`. The extras use the same folder: grass clumps, ground cover, both bank pieces, the water tile, and stepping stones. The original contact sheet stays `contact-sheet.png`. The extras sheet is `contact-sheet-extras.png`. The game replaces each base colour with `assets/shaders/toon.gdshader`. Grass clumps and ground cover are dense MultiMeshes with vertex wind. Banks, water tiles, and stepping stones dress Hearthvale ponds and narrow streams. The Saltglass sheet keeps the sea shader and shoreline foam.
