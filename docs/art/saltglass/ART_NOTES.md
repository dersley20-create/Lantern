# Saltglass Shallows prop kit

Low-poly, Godot-ready coastal props. Glass is faked with stacked colour bands and a bright emissive tip so the game's fresnel rim has an edge to catch — there is no transmissive glass (which would be expensive and would fight the toon shader). 1 unit = 1 m, Y-up glTF, origin at the base centre.

## Assets

| File | What it is | Tris | Size (m, X × Y × H) |
|---|---|---:|---|
| `saltglass_crystal.glb` | Cluster of banded saltglass shards (core / glass / emissive tip). No transmission. | 260 | 0.65 × 0.43 × 1.00 |
| `saltglass_crystal_tall.glb` | Taller hero shard with a smaller companion, ~1.6 m. | 140 | 0.52 × 0.34 × 1.58 |
| `saltglass_driftwood.glb` | Forked driftwood with a salt crust, ~1.9 m long. | 122 | 1.88 × 0.53 × 0.45 |
| `saltglass_reeds.glb` | Reed clump, ~1.4 m tall. | 280 | 0.56 × 0.43 × 1.39 |
| `saltglass_beach_grass.glb` | Short, splayed beach-grass tuft, ~0.55 m. | 380 | 0.52 × 0.51 × 0.53 |
| `saltglass_tidepool.glb` | Rock basin with a still pool (non-transmissive, slightly emissive). | 354 | 1.56 × 1.56 × 0.36 |
| `saltglass_shells.glb` | Clam and spiral shell cluster on a little sand. | 332 | 0.41 × 0.39 × 0.15 |
| `saltglass_beacon.glb` | Weathered buoy / channel marker; metal bands are hidden tech, lamp is emissive. | 312 | 0.56 × 0.56 × 1.48 |

Master blend: `saltglass_kit.blend`.

The tidepool's water is a flat `SG_Pool` disc (slightly emissive, low roughness) sitting in a scooped rock, not a simulated liquid.

The beacon is a weathered buoy / channel marker: metal bands and a vertical seam are the hidden tech, and the lamp is emissive. Place it on sand or at the waterline.

Material names: `SG_Glass`, `SG_GlassCore`, `SG_GlassRim`, `SG_Driftwood`, `SG_DriftwoodDark`, `SG_Reed`, `SG_Grass`, `SG_GrassDry`, `SG_Shell`, `SG_ShellPink`, `SG_Stone`, `SG_StoneDark`, `SG_Pool`, `SG_Sand`, `SG_Beacon`, `SG_BeaconMetal`, `SG_BeaconLamp`, `SG_Salt`.

## Weaknesses

- Banded glass reads clearly from a high camera but will never look like real refraction; that is intentional.
- Reeds and beach grass are tubes, so they stay visible from the Diablo-style camera, but they are a little sparse if used alone — scatter a few copies.
- Shell spirals are a coiled tube, not a true conch; they read at kit scale, not as a close-up hero.
- The beacon lamp is a simple cylinder, not a framed lantern.
