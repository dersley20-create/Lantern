# Art reference

Mood boards and contact sheets live here, next to the notes for each drop. Models themselves live under `assets/models/`.

```
docs/art/<biome_id>/mood-<name>.png
docs/art/<biome_id>/contact-sheet.png
docs/art/<biome_id>/ART_NOTES.md
docs/art/<biome_id>/manifest.json
docs/art/landmarks/
```

`<biome_id>` matches the biome resource: `hearthvale`, `glimmerwood`, `saltglass`, `cloudloft`, `greying`, `underhollows`.

Prop files that belong with a drop:

```
assets/models/props/<biome_id>/<biome_id>_<prop_id>.glb
assets/models/landmarks/wellstone_dormant.glb
assets/models/landmarks/wellstone_restored.glb
```

Living biomes scatter the restored Wellstone where the network is strong. The Greying scatters the dormant ring. Dormant is the unlit default.

Wild creatures (not the companion) live in `assets/models/creatures/cactoro.glb` and `mushnub.glb`. Notes and the contact sheet are in `docs/art/creatures/`.

Hearthvale extras (grass clumps, ground cover, banks, water tile, stepping stones) share `assets/models/props/hearthvale/`. Their sheet is `docs/art/hearthvale/contact-sheet-extras.png`.

See `docs/art/hearthvale/` for the first set.
