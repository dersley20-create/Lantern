# Glimmerwood prop kit

Low-poly, Godot-ready props for the Glimmerwood: a glowing, copper-veined forest where the trees are really engineered antennae. 1 unit = 1 m, Y-up glTF, origin at the base centre. Preview cel uses a 3-step ramp and a fresnel rim to match the game shader; the GLBs themselves are flat named colours plus emission. No outline meshes.

## Assets

| File | What it is | Tris | Size (m, X × Y × H) |
|---|---|---:|---|
| `glimmerwood_glowcap.glb` | Glowcap cluster: proper caps and stems, emissive. | 968 | 0.69 × 0.52 × 0.67 |
| `glimmerwood_tree_copper.glb` | Broader copperbark tree, branched canopy, ~5.5 m. | 1472 | 4.34 × 3.82 × 5.40 |
| `glimmerwood_tree_tall.glb` | Taller antenna-like tree, staggered foliage tiers, ~7 m. | 1376 | 3.22 × 2.94 × 6.65 |
| `glimmerwood_glow_vines.glb` | Arched bough with hanging glow-vines and berries. Origin at the ground. | 548 | 1.73 × 0.42 × 2.13 |
| `glimmerwood_fern.glb` | Fern clump, several fronds. | 1056 | 1.51 × 1.29 × 0.48 |
| `glimmerwood_mossy_log.glb` | Fallen log with moss, ~2 m long. | 192 | 1.84 × 0.44 × 0.42 |
| `glimmerwood_glimmer_crystal.glb` | Banded amber/cyan crystal cluster, emissive tips. | 260 | 0.46 × 0.32 × 0.68 |
| `glimmerwood_root_arch.glb` | Root arch, walkable opening ~1.6 m high, copper vein. | 272 | 2.74 × 0.78 × 2.56 |

Master blend: `glimmerwood_kit.blend`. The glow-vines prop is a ground-rooted arched bough with hanging strands, so it can be scattered without a parent tree. The root arch opening is about 1.6 m high — a character can walk through it.

Material names: `GW_Bark`, `GW_Copper`, `GW_Leaf`, `GW_LeafShadow`, `GW_Moss`, `GW_Stem`, `GW_Glowcap`, `GW_GlowcapUnder`, `GW_GlowBerry`, `GW_Vine`, `GW_Amber`, `GW_Wood`, `GW_WoodEnd`, `GW_Crystal`, `GW_CrystalRim`, `GW_Soil`.

## Weaknesses

- Glowcaps are a small cluster, not a single hero mushroom; the caps read from a high camera but gill detail is only a darker underside, not real gills.
- The two trees share a language (copper vein + clustered foliage). The tall one is narrower and more tiered, but from some angles they can still feel like cousins.
- Fern leaflets are simple diamonds, not notched fronds; they read as a fern mainly from the arching midribs.
- Glow berries on the vines are small spheres; they glow, but they are not winged moths (those would be a creature, not a prop).
