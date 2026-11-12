# Nestkin creatures

Companions are restyled from the Vuena / Popyca *Cute Pets FREE Sample* (CC0). Wild endemic creatures in this folder are restyled from Quaternius **Ultimate Monsters** bases (CC0 / public domain). In both cases the original armature and every animation clip were kept. Raw vendor files stay in `/workspace/lantern-art/_vendor/` and should not be redistributed from this tree.





## Roles

- **Companions** (player-facing pets): the Vuena / Popyca CC0 cat, fox and owl in `/workspace/lantern-art/_vendor/vuena/`. These are the companion bases.
- **Wild endemic creatures** (biome wildlife, not companions): Quaternius Cactoro and Mushnub in `/workspace/lantern-art/_vendor/quaternius/`. They will be reshaped later; they are not companion bases. Do not start work on them or the player model in this drop.


## Licence and sources

- Licence: **CC0 1.0** (public domain), [Quaternius Ultimate Monsters](https://quaternius.com/packs/ultimatemonsters.html).
- Cactoro on Poly Pizza: https://poly.pizza/m/66CYX5UhRK
- Mushnub on Poly Pizza: https://poly.pizza/m/LWKmS30Xxl
- Bundle: https://poly.pizza/bundle/Ultimate-Monsters-Bundle-5oyGWAmOB6
- Official Drive folder (full 50-model pack; only these two were downloaded, as glTF from Poly Pizza): https://drive.google.com/drive/folders/18m4KpzpEzhC9wl7jzr6dUc0N8Jozr79C

Both files arrived with a 4-bone `CharacterArmature` (`Body`, `Head`, `Head2`, `Head3`) and the nine clips listed below. The authored height is about 3.3–3.6 m (Quaternius scale). Leave it as-is in the GLB so the skin stays intact; instance at **0.33** in Godot for a creature about 1.1 m tall. These two are wild endemic wildlife, not companions.

## Assets

| File | Base | Tris | Size (m, X × Y × H) | Reimport |
|---|---|---:|---|---|
| `cactoro_nestkin.glb` | Quaternius Cactoro | 2388 | 4.07 × 3.67 × 3.57| OK |
| `mushnub_nestkin.glb` | Quaternius Mushnub | 1248 | 2.75 × 2.75 × 3.30| OK |

### `cactoro_nestkin` clips

- `CharacterArmature|Yes` — yes
- `CharacterArmature|Walk` — walk
- `CharacterArmature|No` — no
- `CharacterArmature|Jump` — jump
- `CharacterArmature|Idle` — idle
- `CharacterArmature|HitRecieve` — hit
- `CharacterArmature|Death` — death
- `CharacterArmature|Dance` — dance
- `CharacterArmature|Bite_Front` — bite

### `mushnub_nestkin` clips

- `CharacterArmature|Yes` — yes
- `CharacterArmature|Walk` — walk
- `CharacterArmature|No` — no
- `CharacterArmature|Jump` — jump
- `CharacterArmature|Idle` — idle
- `CharacterArmature|HitRecieve` — hit
- `CharacterArmature|Death` — death
- `CharacterArmature|Dance` — dance
- `CharacterArmature|Bite_Front` — bite

Shared clip set (both models): **Idle**, **Walk**, **Jump**, **Dance**, **Bite_Front**, **HitRecieve**, **Death**, **Yes**, **No**. There is no run, eat or sleep clip on these bases.

Materials: `NK_Cactus`, `NK_Arm`, `NK_Thatch`, `NK_Band`, `NK_Cap`, `NK_Stem`, `NK_EyeWhite`, `NK_EyeDark`. The hat band (`NK_Band`) and cap (`NK_Cap`) are emissive glimmer. Extra nubs were skipped so the original skin and scale were not disturbed.

## Vuena Blocky Pets free sample (companion-base comparison)

The Vuena / Popyca CC0 sample is in `/workspace/lantern-art/_vendor/vuena/` (https://vuena.itch.io/blocky-pets-free). Nothing was purchased; only the free cat, fox and owl were used. Contents and clips:

- 3 animals: **cat**, **fox** (19-bone skeleton), **owl** (13-bone bird skeleton).
- Formats: GLB and FBX, full mesh + mobile LOD, 1 unit = 1 m.
- 12 clips each, 30 fps, in place: `idle`, `idle_alt`, `walk`, `run` (owl: `fly`), `jump`, `eat`, `sit`, `sleep`, `attack`, `call`, `hit`, `death`. Mouths open (Jaw bone) and eyes blink.
- Licence of the free sample: CC0 1.0. The paid full pack uses a separate royalty-free licence and was not downloaded.

Compared with Cactoro / Mushnub: Vuena's sample is a stronger *companion* base if you want eat / sleep / sit / run (or fly) and a mouth that opens. The Quaternius pair have a much simpler 4-bone stack (no legs, no jaw), a shorter clip list, and a more monster-like bite / yes / no / dance set. For Nestkin village pets, Vuena's cat / fox / owl cover idle–sleep loops more completely; for plant-like Glimmerwood critters, the Quaternius cactus and mushroom already match the look, which is why they were restyled here.

## Weaknesses

- The 4-bone stack has no legs, arms-as-bones, or jaw, so walk is a body bounce rather than footsteps, and there is no eat or sleep clip to restyle.
- Head is not parented to Body in the imported rig (they are keyed separately); that was left alone.
- Mesh additions are simple ico nubs and tufts, fully weighted to a single bone, not painted across joints.
- Cactoro still wears the original sombrero silhouette; the restyle is colour and an emissive hat band, not a new hat.
- As authored the models are ~3.5 m tall. The GLBs keep that size so the skin is not rewritten; instance at 0.33 in engine for a ~1.1 m wild endemic creature (not a companion).
- Preview cel on the contact sheet is a 3-step EEVEE ShaderToRGB; the shipped GLBs are flat colour + emission.

## `fox_hearthvale` (Hearthvale companion)

Source: Vuena / Popyca *Cute Pets FREE Sample* (`animal_fox.glb`), **CC0 1.0**. Files: `/workspace/lantern-art/_vendor/vuena/`. Page: https://vuena.itch.io/blocky-pets-free

The original 19-bone armature and all 12 clips were kept. The export uses the mobile **LOD1** mesh plus new leafy geometry, under the ~5k triangle budget. Silhouette: a bushy leaf tail with a pointed tip, a sprout-and-blossom crown between the ears, and petal-tipped ears. Eyes are a single dark glossy sphere with one white highlight, plus a soft blush oval, all Head-weighted. The face around the eyes is a single body colour, with no leftover albedo patches. Ear petals are snapped onto the real ear tips and grow along the ear, with their bases pushed into the tip so they no longer float. Hearthvale palette (meadow greens, warm cream, flower accents) as flat named colours; honey-gold emissive glimmer freckles on the cheeks.

| File | Base | Tris | Size (m, X × Y × H) | Reimport |
|---|---|---:|---|---|
| `fox_hearthvale.glb` | Vuena fox LOD1 | 4768 | 0.43 × 0.94 × 0.68 | OK |

Clips:

- `walk`
- `sleep`
- `sit`
- `run`
- `jump`
- `idle`
- `idle_alt`
- `hit`
- `eat`
- `death`
- `call`
- `attack`

Materials: `NK_Blush`, `NK_Cream`, `NK_EyeDark`, `NK_Flower`, `NK_Glimmer`, `NK_Highlight`, `NK_Leaf`, `NK_LeafLit`, `NK_Meadow`, `NK_Nose`, `NK_Paw`, `NK_Petal`, `NK_PetalSoft`, `NK_Stem`

Compare: `fox_hearthvale_compare.png`.

### Fox weaknesses

- Eyes are 20-segment UV spheres, much smoother than the old icospheres, but an extreme close-up still shows a slight polygonal rim. Blush is a single solid oval, so the edge is a hard colour cut, not a soft painted falloff. The game toon shader has no real specular, so the 'gloss' is the white highlight mesh.
- New leaves, petals, the crown, eyes, blush and freckles are each fully weighted to a single bone (Tail_1 / Tail_2 / Head / Ear_L / Ear_R), not blended across joints, so a leaf sitting near a tail joint can look a little stiff.
- The stock fur tail is slimmed, not deleted; a little of the original tail volume is still in there under the leaves.
- Flat colours are assigned by sampling the source albedo, then the eye and lid region is forced to a single body colour so stray cream or white patches do not ring the eyes. A few faces around the muzzle edge or paw line may still be classified slightly wrong.
- Eyes are weighted to Head, not to the Lids bone, so a blink will not close the separate eyeballs (the lid verts still move). From the isometric camera the eyes stay readable either way.
- The sleep clip is a held lying pose (almost no mid-clip bone motion). New parts do follow a pose change: idle to sleep moves the Head and tail.
- Preview cel on the compare sheet is a 3-step EEVEE ShaderToRGB with a rim; the shipped GLB is flat colour + emission, with no outline meshes.


## `cat_glimmerwood` (Glimmerwood companion)

Source: Vuena / Popyca *Cute Pets FREE Sample* (`animal_cat.glb`), **CC0 1.0**. Files: `/workspace/lantern-art/_vendor/vuena/`. Page: https://vuena.itch.io/blocky-pets-free

The original 19-bone armature and all 12 clips were kept (LOD1 mesh). Silhouette: a leaf-wrapped tail ending in an emissive glowcap, a glowcap sprout with a leaf rosette between the ears, and leaf-and-glowcap ear tips. Eyes are a single dark glossy sphere with one white highlight, plus a soft blush oval, all Head-weighted and centred in the sockets. The face around the eyes is a single moss colour, with no leftover albedo patches. Glimmerwood palette (moss, moth-silk, copper, teal glowcap, amber) as flat named colours, with teal emissive glimmer freckles.

| File | Base | Tris | Size (m, X × Y × H) | Reimport |
|---|---|---:|---|---|
| `cat_glimmerwood.glb` | Vuena cat LOD1 | 4680 | 0.40 × 0.56 × 0.62 | OK |

Clips:

- `walk`
- `sleep`
- `sit`
- `run`
- `jump`
- `idle`
- `idle_alt`
- `hit`
- `eat`
- `death`
- `call`
- `attack`

Materials: `NK_Amber`, `NK_Blush`, `NK_EyeDark`, `NK_Glimmer`, `NK_Glowcap`, `NK_Highlight`, `NK_Leaf`, `NK_LeafLit`, `NK_Moss`, `NK_MossShadow`, `NK_PetalSoft`, `NK_Silk`, `NK_Stem`

Compare: `cat_glimmerwood_compare.png`.

### Cat weaknesses

- Eyes are 20-segment UV spheres, much smoother than the old icospheres, but an extreme close-up still shows a slight polygonal rim. Blush is a single solid oval, so the edge is a hard colour cut, not a soft painted falloff. The game toon shader has no real specular, so the 'gloss' is the white highlight mesh.
- New leaves, caps, eyes, blush and freckles are fully weighted to a single bone, not blended across joints.
- The stock tail is slimmed, not deleted, so a little of the original volume sits under the leaves.
- The eye and lid region is forced to a single moss colour so stray silk or eye-texture patches do not ring the eyes. A few faces around the muzzle edge, paw line or inner-ear may still be classified slightly wrong.
- Eyes are weighted to Head, not Lids, so blinks will not close the separate eyeballs.
- The sleep clip is a held lying pose; idle to sleep still moves the new head and tail parts.
- Preview cel is 3-step EEVEE ShaderToRGB with a rim; the shipped GLB is flat colour + emission, no outline meshes.


## `owl_cloudloft` (Cloudloft companion)

Source: Vuena / Popyca *Cute Pets FREE Sample* (`animal_owl.glb`), **CC0 1.0**. Files: `/workspace/lantern-art/_vendor/vuena/`. Page: https://vuena.itch.io/blocky-pets-free

The original 13-bone bird armature and all 12 clips (including fly rather than run) were kept (LOD1 mesh). The owl has no ear bones, so tuft extensions are Head-weighted. Silhouette: pine-needle and heather extensions on the ear tufts, a small wind-crystal between them, leaf-feathers on the trailing edge of each wing, and a few tail feathers. Eyes are a single dark glossy sphere with one white highlight, plus a soft blush oval, all Head-weighted. The face around the eyes is a single pine colour, with no leftover albedo patches. Cloudloft palette (pine, wool, slate, heather, wind-crystal) as flat named colours, with pale emissive glimmer on the brow.

| File | Base | Tris | Size (m, X × Y × H) | Reimport |
|---|---|---:|---|---|
| `owl_cloudloft.glb` | Vuena owl LOD1 | 4768 | 0.47 × 0.41 × 0.67 | OK |

Clips:

- `walk`
- `sleep`
- `sit`
- `jump`
- `idle`
- `idle_alt`
- `hit`
- `fly`
- `eat`
- `death`
- `call`
- `attack`

Materials: `NK_Bark`, `NK_Blush`, `NK_Crystal`, `NK_EyeDark`, `NK_Glimmer`, `NK_Heather`, `NK_Highlight`, `NK_Leaf`, `NK_LeafLit`, `NK_Pine`, `NK_PineShadow`, `NK_Slate`, `NK_Wool`

Compare: `owl_cloudloft_compare.png`.

### Owl weaknesses

- Eyes are 20-segment UV spheres, much smoother than the old icospheres, but an extreme close-up still shows a slight polygonal rim. Blush is a single solid oval, so the edge is a hard colour cut, not a soft painted falloff. The game toon shader has no real specular, so the 'gloss' is the white highlight mesh.
- Wing leaves are fully weighted to Wing_L / Wing_R and tuft extensions to Head, with no blending across the shoulder, so a leaf near the wing root can look a little stiff in fly.
- The eye and lid region is forced to a single pine colour so stray wool or eye-texture patches do not ring the eyes. The belly chevron is flattened to wool / pine rather than a painted pattern; a few faces around the beak or feet may still be slightly wrong.
- Eyes are weighted to Head, not Lids, so blinks will not close the separate eyeballs.
- The sleep clip is a held pose; idle to sleep still moves the new head parts.
- Preview cel is 3-step EEVEE ShaderToRGB with a rim; the shipped GLB is flat colour + emission, no outline meshes.

