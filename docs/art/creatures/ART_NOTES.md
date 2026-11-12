# Nestkin creatures

Restyled from Quaternius **Ultimate Monsters** bases (CC0 / public domain). The original armature and every animation clip were kept; only the mesh materials were changed. The sombrero band and the mushroom cap are emissive glimmer. Raw source files stay in `/workspace/lantern-art/_vendor/quaternius/` and should not be redistributed from this tree.

## Licence and sources

- Licence: **CC0 1.0** (public domain), [Quaternius Ultimate Monsters](https://quaternius.com/packs/ultimatemonsters.html).
- Cactoro on Poly Pizza: https://poly.pizza/m/66CYX5UhRK
- Mushnub on Poly Pizza: https://poly.pizza/m/LWKmS30Xxl
- Bundle: https://poly.pizza/bundle/Ultimate-Monsters-Bundle-5oyGWAmOB6
- Official Drive folder (full 50-model pack; only these two were downloaded, as glTF from Poly Pizza): https://drive.google.com/drive/folders/18m4KpzpEzhC9wl7jzr6dUc0N8Jozr79C

Both files arrived with a 4-bone `CharacterArmature` (`Body`, `Head`, `Head2`, `Head3`) and the nine clips listed below. The authored height is about 3.3–3.6 m (Quaternius scale). Leave it as-is in the GLB so the skin stays intact; instance at **0.33** in Godot for a companion about 1.1 m tall.

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

Tried https://vuena.itch.io/blocky-pets-free (CC0 sample: cat, fox, owl). A download without an itch.io account was not possible: GET on the file endpoint redirected to the page, and later POSTs were rate-limited (HTTP 429). Nothing was purchased. Contents and clips below are from the public page.

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
- As authored the models are ~3.5 m tall. The GLBs keep that size so the skin is not rewritten; instance at 0.33 in engine for a ~1.1 m companion.
- Preview cel on the contact sheet is a 3-step EEVEE ShaderToRGB; the shipped GLBs are flat colour + emission.
