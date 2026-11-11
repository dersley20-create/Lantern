# Lantern

Working title: **The Lantern Below**. A cosy 3D walk through **Veyla**, a seeded world whose magic is ancient terraforming tech: nanomachine glimmer, and standing-stone relays called Wellstones.

This repository is the Godot 4 gameplay prototype. Character and environment art are made separately in Blender and dropped in as `.glb` files. Until then, everything on screen is a placeholder mesh.

Ships as a **paid-upfront Android game on Google Play, with no ads**. Package id: `com.dersley.nestkin`. Export presets and signing keys are not in this repo (and are gitignored).

Tested with **Godot 4.7.2** (GDScript). The project uses the **Mobile** renderer.

## Run

1. Install [Godot 4.7.x](https://godotengine.org/download) (standard build, not .NET).
2. Open this folder in the Godot project manager and press Play, or from a shell:

```bash
godot --path .
```

You start on foot in Veyla, with your first raised creature beside you. The world streams in around you and keeps going.

Headless checks (determinism, chunk seams, biomes, slopes, virtual stick):

```bash
godot --headless --path . -s res://scripts/tests/test_world.gd
```

## Controls

Landscape only. The handheld orientation is **sensor landscape**, set in one place: **Project Settings → Display → Window → Handheld → Orientation** (`display/window/handheld/orientation`).

| Input | Action |
| --- | --- |
| W A S D or arrow keys | Walk, relative to the camera |
| Left side of the screen | Virtual stick (shown only while your thumb is down) |
| Mouse wheel, `-` / `=`, or pinch | Zoom, within a short range |
| Q / E, middle-mouse drag, or a drag on the right side of the screen | Orbit the camera |

There is no HUD. No health, no minimap, no prompts. The stick is the only interface, and it disappears when you lift your finger.

The camera sits high and looks down at about 55°, framed for a landscape phone: the view leads a little ahead of the walker. Pitch, distance, and field of view live on the `FollowCamera` node in `scenes/main.tscn`.

## Folder map

```
scenes/            main scene, creatures, camera, placeholder props
scripts/           gameplay, generator, tests
resources/         WorldConfig, biomes, prop definitions
assets/models/     drop imported .glb files here (see below)
assets/shaders/    terrain and water (mobile-friendly)
```

| Path | What belongs there |
| --- | --- |
| `assets/models/creatures/` | The player and raised creatures |
| `assets/models/props/` | Trees, rocks, flowers, Wellstones, anything the biomes scatter |
| `assets/models/environment/` | One-off set dressing that is not scattered by the generator |

## Blender models

Export **glTF binary (`.glb`)**.

- **1 unit = 1 metre**
- **Y-up** (glTF's default; in Blender's exporter, +Y up)
- **Origin at the base**, on the ground contact. Feet for creatures, the trunk base for a tree, the bottom of a stone

Godot imports a `.glb` as a `PackedScene`.

**Props.** Put the file in `assets/models/props/`, then open the matching resource under `resources/props/` and assign it to the `scene` field. Biomes list those resources, so one assignment updates every chunk that scatters it.

- Several `MeshInstance3D` children (trunk and canopy, for example) become one MultiMesh each, which is what we want on a phone.
- Set `instance_as_scene` on the prop if the model needs collision, lights, or animation. Wellstones do this today.
- `tint` multiplies `StandardMaterial3D` albedo. `emission_surface_names` limits the emission override to named meshes (`Canopy`, `Blossom`, …). Shader materials are left as the file authored them.

**Creatures.** Put the file in `assets/models/creatures/`. On the Player or on `FirstRaised` (the companion), assign `visual_scene`. The placeholder hides and the imported scene is parented under `VisualRoot`, which already faces movement. Keep the origin at the feet so they stand on the terrain. The player's collision stays a capsule until you replace it on purpose.

`FirstRaised` is the player's **first raised creature**, not a separate pet. Swap that one scene when the real model exists.

## World

The surface is chunked, seeded, and deterministic. The same seed rebuilds the same land, including prop placement. Chunk edges sample world coordinates, so they meet.

Edit `resources/world/world_config.tres` (or select the World node in `scenes/main.tscn` and expand the config). The useful knobs:

- `world_seed`
- `load_radius`, `lod1_distance`, `prop_radius` (keep these small on device; defaults are a 5×5 chunk window, props only on the inner 3×3)
- noise frequencies and amplitudes
- biome thresholds (`highlands_elevation`, `shallows_moisture`, `greying_wellstone`, `glimmer_moisture`, …)
- the biome list

Noise is FastNoiseLite. Height is a broad continent plus a low hill layer, so the ground rolls instead of spiking. Wet low ground eases toward a shallow shelf; the water plane is visual only and the shelf stays walkable.

| Biome | Where it shows up |
| --- | --- |
| Hearthvale | Default tame ground: meadows and farmland |
| The Glimmerwood | Moist land where the Wellstone network is still alive |
| Saltglass Shallows | Low, wet coast |
| Cloudloft Highlands | High ground |
| The Greying | Mid elevations where the network has gone dormant |
| The Underhollows | **Not on the surface.** Stub resource for a future underground layer (`surface_enabled = false`) |

Each surface biome has its own ground colour and a list of props with density, slope limit, and (for Wellstones) a single roll per chunk so they stay landmarks.

Chunks underfoot are built before you can move, so you spawn standing on collision. Further chunks are meshed off the main thread and attached a few per frame. The outer ring uses a coarser grid and skips props. A short skirt hides LOD cracks.

Scattered trees, rocks, and flowers are MultiMeshes and do not block movement. Wellstones are real nodes with a box collider.

## Android notes

- Renderer: Mobile, including when you press Play on desktop, so the editor matches the device.
- Orientation: sensor landscape.
- Textures are set to import ETC2/ASTC so future maps are phone-sized. There are no authored textures yet.
- Screen stays awake while the game is in front (`keep_screen_on`).
- Do not commit `export_presets.cfg` or a keystore. The Play package id is `com.dersley.nestkin`.

## Known gaps

- The Underhollows are a note, not a cave system.
- No raising, combat, or other creature play yet. You can only walk with the first one.
- Placeholder art. No audio.
- Props other than Wellstones have no collision.
- LOD seams are hidden with skirts, not stitched vertex-for-vertex.
- Water is a moving transparent plane, not a simulation.
