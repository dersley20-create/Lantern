# Veyla as a planet

The current game is a seeded tangent patch: 32 m chunks on a flat heightfield, streamed around the player. Andrew's call is that Veyla is **not** endless. It is one Earth-sized sphere. You can walk all the way around it, and the same seed always rebuilds the same place.

This note is the plan for getting there. The code that is safe to ship now is `PlanetMap` in `scripts/world/planet.gd`: wrap a flat metre coordinate into one circumference, and turn that into longitude and latitude. Chunk streaming, collision, and the camera still use the flat patch, so Bramblecross and the tests stay as they are.

## Size

1 unit is 1 metre.

| | metres |
| --- | --- |
| Mean radius | 6,371,000 |
| Circumference | about 40,030,173 |
| Chunk | 32 |

A full trip around the equator is about 1.25 million chunks. The phone never holds that. It holds the ring around the player, the same way it does today.

## Cube-sphere chunks

Keep the chunk as the unit of work. Give each chunk a face on a cube (six faces) and a coordinate on that face, then push the face onto the sphere:

1. Face point in `[-1, 1] x [-1, 1]`.
2. Normalise to the unit sphere.
3. Scale by the planet radius.
4. Sample height along that normal and add it.

Neighbouring chunks on the same face share an edge in face space, so the seam rule we already have (sample by world position, not by a local grid index) still applies. Faces meet at the cube edges. Those edges need the same sample, taken in a shared angular coordinate, or a short skirt the way LOD cracks are hidden now.

The height function stays the seeded noises. Their inputs become longitude and latitude (and, later, a small local east/north offset inside the chunk) instead of raw `x, z`.

## Floating origin

Single-precision positions start to wobble well before you have walked a thousand kilometres. The camera, the player, and the visible chunks should live near the origin:

- Keep a double-style anchor: planet position of the player in metres along the sphere, or as a longitude/latitude pair plus height.
- Each frame, rebuild chunk origins relative to the player so the player stays near `(0, 0, 0)` in the scene.
- Noise and biome samples use the absolute planet coordinate, never the camera-relative one.

The anchor moves when the player has walked a few chunks, not every frame, so physics does not jitter.

## Biomes

Replace the flat noise thresholds with three inputs that wrap:

- **Latitude.** Hearthvale and farmland favour the mild bands. The Greying can sit in a belt where the Wellstone field is weak. Poles are Cloudloft or a later ice variant. The equator can run hotter and is not required for the first planet.
- **Moisture.** The existing moisture noise, sampled in longitude/latitude so it repeats after one trip around.
- **Height.** The same coast, shelf, and highland rules, measured along the sphere normal. Saltglass stays the wet low coast. Glimmerwood stays moist ground where the Wellstone field is alive.

The Underhollows stay off the surface. A later shell under the radius can use the same longitude and latitude.

## Curvature and the isometric camera

The follow camera sits about 16 m back and looks down at roughly 55°. The ground it shows is a few dozen metres across. On an Earth-sized sphere the drop over 30 m is about a millimetre (`distance² / (2 radius)`). The high camera will not read the planet as a curve. Horizon haze and the existing fog do that job at distance. Do not tilt chunks to fake a cartoon curve. It would fight the flat collision the player walks on.

What the player should feel instead: travel is finite, biomes change with latitude, and walking long enough brings you back to a place you recognise.

## Mobile budget

The planet does not raise the budget. The phone still renders the near ring only.

| | keep |
| --- | --- |
| Loaded chunks | the current load radius (a 5×5 window) |
| Props and grass | the inner 3×3, scaled by `visual_quality` |
| Draw | MultiMesh for props and grass, one toon shader |
| Shadows | the quality resource's shadow distance |
| Physics | heightfield collision on the loaded chunks only |
| Streaming | a few chunk builds per frame, off the main thread |

Cube-sphere math is a handful of normalises per vertex. That is cheap next to the mesh upload. Do the heavy sample on the worker, and keep the vertex count where it is (33×33 up close, 17×17 far).

## What is in the build now

`PlanetMap.wrap_xz` folds easting and northing into one circumference, centred on zero. `longitude_deg` and `latitude_deg` turn those metres into degrees. The same inputs always return the same outputs. Chunk streaming does **not** call them yet. Turning the live world on would move every seam, the village pad, and the spawn search. That is the next step, after the floating origin, not before.
