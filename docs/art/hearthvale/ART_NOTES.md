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
| `hv_fence_segment.glb` | Fence, 3 rails, post on the **-X** end only | 72 | 2.08 × 0.13 × 1.22 |
| `hv_hay_bale.glb` | Round bale with twine bands | 320 | 0.96 × 0.76 × 0.95 |
| `hv_tree_oak.glb` | Broad oak, darker underside | 628 | 4.52 × 3.67 × 4.58 |
| `hv_tree_fruit.glb` | Smaller orchard tree, a few apples | 608 | 2.53 × 2.20 × 3.39 |
| `hv_flower_clump.glb` | Mixed wildflowers on a small mound | 1052 | 0.63 × 0.52 × 0.51 |
| `hv_bush.glb` | Round leafy bush | 500 | 1.48 × 1.26 × 1.17 |
| `hv_rock.glb` | River stone with a moss cap | 100 | 0.81 × 0.70 × 0.60 |
| `hv_crop_patch.glb` | 2 m wheat tile with a thin soil base | 1236 | 2.06 × 2.18 × 1.51 |

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
- `hearthvale/manifest.json` and `hearthvale/verify_report.json` — triangle counts and re-import checks

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

## Repo paths

The kit was renamed onto the project convention. Prop id is the scatter resource id.

| Artist file | In the repo |
| --- | --- |
| `hv_fence_segment.glb` | `assets/models/props/hearthvale/hearthvale_fence.glb` |
| `hv_hay_bale.glb` | `assets/models/props/hearthvale/hearthvale_hay_bale.glb` |
| `hv_tree_oak.glb` | `assets/models/props/hearthvale/hearthvale_oak.glb` |
| `hv_tree_fruit.glb` | `assets/models/props/hearthvale/hearthvale_fruit_tree.glb` |
| `hv_flower_clump.glb` | `assets/models/props/hearthvale/hearthvale_flower_clump.glb` |
| `hv_bush.glb` | `assets/models/props/hearthvale/hearthvale_bush.glb` |
| `hv_rock.glb` | `assets/models/props/hearthvale/hearthvale_rock.glb` |
| `hv_crop_patch.glb` | `assets/models/props/hearthvale/hearthvale_crop_patch.glb` |

Mood boards are `docs/art/<biome_id>/mood-<biome_id>.png`. The contact sheet is `docs/art/hearthvale/contact-sheet.png`. The game replaces each base colour with `assets/shaders/toon.gdshader` at load.
