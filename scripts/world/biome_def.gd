class_name BiomeDef
extends Resource

## Look and scatter rules for one region of Veyla.
## Ground colour is sampled per vertex. Props reference scenes or imported .glb files.

@export var id: StringName = &""
@export var display_name: String = ""
@export var ground_color: Color = Color(0.5, 0.6, 0.4, 1)
@export_range(0.0, 0.4, 0.01) var ground_color_variance: float = 0.06
## Packed into terrain vertex alpha. Small on purpose: the mobile renderer has no bloom.
@export_range(0.0, 1.0, 0.01) var ground_glow: float = 0.0
## False for biomes that are not part of the walkable surface (the Underhollows).
@export var surface_enabled: bool = true
@export_multiline var lore_note: String = ""
@export var props: Array[PropDef] = []
