# Hearthvale props

Eight scatter and farm models. Each is a glTF binary, under 1,300 triangles, with flat named materials and plain colours.

- 1 unit = 1 metre
- Y-up
- Origin at the base centre

| File | prop id | Size | Materials |
| --- | --- | --- | --- |
| `hearthvale_fence.glb` | fence (farm plot only) | 2.0 m along local X, about 1.05 m tall | Wood |
| `hearthvale_hay_bale.glb` | `hay_bale` | about 1.25 × 0.64 × 0.86 m | Hay, Band |
| `hearthvale_oak.glb` | `oak` | trunk to 2.15 m, canopy above | Bark, Leaves |
| `hearthvale_fruit_tree.glb` | `fruit_tree` | shorter trunk, round canopy, fruit | Bark, Leaves, Fruit |
| `hearthvale_flower_clump.glb` | `flower_clump` | cluster about 0.6 m across | Stem, Petal, PetalWarm |
| `hearthvale_bush.glb` | `bush` | about 1.1 m across, under 1 m tall | Leaves |
| `hearthvale_rock.glb` | `hearthvale_rock` | about 1 m across | Stone |
| `hearthvale_crop_patch.glb` | crop (farm plot only) | 2.0 m × 2.0 m | Soil, Crop |

The fence tiles every 2.0 m. The spawn chunk builds one plot from those tiles and four crop patches, ahead of the player. Oaks, fruit trees, bushes, flower clumps, rocks, and a few hay bales also scatter through the meadow.

Trunks and rocks get a simple collider (cylinder or sphere). The fence and hay bale on the plot use a box. Bushes, flowers, and crops do not block movement.

The game swaps every plain material for `assets/shaders/toon.gdshader` at load, so the authored colour is the cel albedo. Do not depend on textures for this drop.

Mood boards for this biome belong beside this file as `mood-<name>.png`, with a `contact-sheet.png` of the whole set.
