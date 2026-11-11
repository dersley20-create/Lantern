# Lantern

Working title: **The Lantern Below**. A cosy 3D walk through **Veyla**, a seeded world whose magic is ancient terraforming tech: nanomachine glimmer, and standing-stone relays called Wellstones.

This repository is the Godot 4 gameplay prototype. Hearthvale props are imported `.glb` files. Other biomes and the creatures are still placeholders until their drops arrive.

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
assets/models/     imported .glb files (see Art drops)
assets/shaders/    cel lighting, terrain, and water
docs/art/          mood boards, contact sheets, and per-drop notes
```

| Path | What belongs there |
| --- | --- |
| `assets/models/creatures/` | The player and raised creatures |
| `assets/models/props/<biome_id>/` | Scatterable props for that biome |
| `assets/models/environment/` | One-off set dressing that is not scattered by the generator |
| `docs/art/<biome_id>/` | Mood boards, contact sheet, ART_NOTES, manifest |

## Art drops

Future drops use these paths exactly. `<biome_id>` is the id on the biome resource (`hearthvale`, `glimmerwood`, `saltglass`, `cloudloft`, `greying`, `underhollows`). `<prop_id>` is short and snake_case (`oak`, `fence`, `crop_patch`).

| What | Path |
| --- | --- |
| Prop model | `assets/models/props/<biome_id>/<biome_id>_<prop_id>.glb` |
| Creature model | `assets/models/creatures/<creature_id>.glb` |
| Mood board | `docs/art/<biome_id>/mood-<name>.png` |
| Contact sheet | `docs/art/<biome_id>/contact-sheet.png` |
| Notes and manifest | `docs/art/<biome_id>/ART_NOTES.md` and `docs/art/<biome_id>/manifest.json` |
| Wellstones | `assets/models/landmarks/wellstone_dormant.glb` and `wellstone_restored.glb` |

Example already in the repo: `assets/models/props/hearthvale/hearthvale_oak.glb`.

Export **glTF binary (`.glb`)**.

- **1 unit = 1 metre**
- **Y-up** (glTF's default; in Blender's exporter, +Y up)
- **Origin at the base centre** (ground contact). Feet for creatures. A fence segment runs along local X; the Hearthvale fence tiles every **2.0 m**, and the crop patch is **2.0 m × 2.0 m**
- Flat named materials with plain colours. The game replaces them at runtime with `assets/shaders/toon.gdshader` (stepped light plus a rim). Do not rely on textures for the first drops

**Props.** Add a `PropDef` under `resources/props/` that points `scene` at the `.glb`, and list it on the biome. Several surfaces (bark and leaves) stay on one mesh and become one MultiMesh. Emissive glTF materials stay emissive under the toon shader. Set `collision_kind` to `cylinder` for a trunk or `sphere` for a rock. Set `instance_as_scene` only when the model needs real nodes (Wellstones). Living biomes use the restored Wellstone; the Greying uses the dormant ring. Fences and crop patches are not sprinkled through the meadow; the spawn chunk builds one fenced plot from the 2 m tiles. A Cloudloft rope-bridge roll lays three 3 m segments in a line.

**Creatures.** Put the file in `assets/models/creatures/`. `FirstRaised` is still Pyreleaf, the companion: `assets/models/creatures/pyreleaf.glb`, Y-up, faces +Z, origin at the feet. It plays `Idle` and hops a little while following. A later drop will replace that companion. Emissive parts stay glowing; the rest use the project toon shader.

Cactoro and Mushnub are wild, not the companion. Near chunks spawn a deterministic group of up to three: Cactoro on the Saltglass and on dry Hearthvale edges, Mushnub in the Glimmerwood and on damp Hearthvale. They idle, walk a few metres, then idle again, with an occasional Yes, Dance, or Jump. If you step closer than about 4 m they drift off. Past 30 m the clip pauses. The GLBs are the Quaternius scale (about 3.5 m); the world instances them at 0.33.

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

Scattered props are MultiMeshes. Trees use a trunk cylinder and rocks a sphere, so they block you without a triangle mesh. Wellstones are real nodes with a box collider. Hearthvale also places one fenced plot, with 2 m fence tiles and 2 m crop patches, in front of the spawn point.

## Android notes

- Renderer: Mobile, including when you press Play on desktop, so the editor matches the device.
- Orientation: sensor landscape.
- Textures are set to import ETC2/ASTC so future maps are phone-sized. There are no authored textures yet.
- Screen stays awake while the game is in front (`keep_screen_on`).
- Do not commit `export_presets.cfg` or a keystore. The Play package id is `com.dersley.nestkin`.

## Visual quality

`resources/world/visual_quality.tres` is the phone knob. It is `medium` by default.

| Setting | Low | Medium | High |
| --- | --- | --- | --- |
| Hearthvale grass tufts per near chunk | 70 | 280 | 520 |
| Fireflies / glimmer motes | off | 22 | 40 |
| Shoreline foam ribbon | off | on | on |
| Leaf and grass wind | off | on | on |
| Shadow distance | 26 m | 44 m | 60 m |

Lighting stays at a warm morning unless `DayLight.cycle` is turned on. A full day then takes `day_length_seconds` (12 minutes by default) and night is a dim moon, not a black screen.

## Known gaps

- The Underhollows are a note, not a cave system.
- No raising, combat, or other creature play yet. You can only walk with the first one.
- The player mesh is still a placeholder. No audio. The companion is still Pyreleaf until the next creature drop.
- Tree and rock collision is a trunk cylinder or a sphere, not the rendered mesh. Fences on the spawn plot use a thin box.
- LOD seams are hidden with skirts, not stitched vertex-for-vertex.
- Water is one transparent plane that follows the player, lifted so it meets the Saltglass sand. Foam is a ribbon of discs on that waterline (off on low quality). The water shader also softens the edge when the device exposes a depth texture.
