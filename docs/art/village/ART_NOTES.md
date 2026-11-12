# Bramblecross village kit

Low-poly village props for Bramblecross, in the Hearthvale style. 1 unit = 1 m, Y-up glTF, origin at the base centre. Doors and the cart shafts face **+Y** (front). Windows and lamps are emissive. Grandmother's cottage is the player's start point: a 2.1 m door you can walk up to, a thatched roof, a chimney, warm windows and a lantern by the door.

## Assets

| File | What it is | Tris | Size (m, X × Y × H) |
|---|---|---:|---|
| `village_grandmother_cottage.glb` | Player start cottage, ~7 m wide, thatched roof, chimney, 2.1 m door on +Y, warm emissive windows and a lantern by the door. | 788 | 7.28 × 5.94 × 5.51 |
| `village_cottage_a.glb` | Small gable-front thatched cottage, door on +Y. | 432 | 4.34 × 5.26 × 4.71 |
| `village_cottage_b.glb` | Mid cottage with a stone lower storey, two front windows and flower boxes, door on +Y. | 596 | 5.76 × 5.28 × 5.01 |
| `village_cottage_c.glb` | Shingle-roof cottage, door off-centre on +Y. | 328 | 4.84 × 4.82 × 4.66 |
| `village_well.glb` | Village well with a thatched cap, crank and hanging bucket. | 312 | 1.50 × 1.24 × 2.70 |
| `village_lantern_post.glb` | Timber post with a metal arm and an emissive lamp. | 136 | 0.36 × 0.76 × 2.72 |
| `village_cart.glb` | Two-wheeled hay cart, shafts toward +Y. | 236 | 1.50 × 2.98 × 1.24 |
| `village_garden_bed.glb` | Raised wooden garden bed with soil, leafy plants and a few flowers. | 256 | 1.80 × 1.10 × 0.49 |

Master blend: `village_kit.blend`.\n\nThe grandmother cottage is about 7 m wide including eaves. Smaller cottages A–C are variations (gable-front thatch, stone-base thatch, shingle roof).\n\nMaterial names: `HV_Plaster`, `HV_PlasterWarm`, `HV_Wood`, `HV_WoodDark`, `HV_Thatch`, `HV_ThatchShadow`, `HV_Shingle`, `HV_Stone`, `HV_StoneDark`, `HV_Moss`, `HV_Door`, `HV_Window`, `HV_Lamp`, `HV_Metal`, `HV_Soil`, `HV_Hay`, `HV_Leaf`, `HV_LeafShadow`, `HV_Stem`, `HV_FlowerYellow`, `HV_FlowerPink`, `HV_FlowerWhite`, `HV_WellDark`.

## Weaknesses

- Cottages are boxy timber-frame volumes, not irregular handmade walls, and the doors are solid planes — there is no interior or door opening.\n- Thatch is layered slabs, not individual bundles; shingles are a flat colour, not a tiled texture.\n- Windows are simple framed panes with a single mullion, not leaded glass.\n- The cart wheels are low-segment cylinders and the hay is a simple mound.\n- The well roof and crank are simplified, and the garden plants are ico clumps rather than identifiable crops.
