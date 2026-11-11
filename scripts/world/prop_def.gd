class_name PropDef
extends Resource

## A scatterable placeholder or imported model.
##
## Point [member scene] at a PackedScene: either one of the placeholder scenes
## under res://scenes/props/ or a .glb dropped in res://assets/models/props/.
## Static meshes are batched with MultiMesh. Set [member instance_as_scene]
## for collision, lights, or anything that must stay a real node (rare
## landmarks such as Wellstones).

@export var id: StringName = &""
@export var scene: PackedScene
@export var instance_as_scene: bool = false
## When true, the chunk rolls this prop once instead of per scatter cell.
@export var once_per_chunk: bool = false
@export_range(0.0, 1.0, 0.01) var density: float = 0.1
@export var min_scale: float = 0.85
@export var max_scale: float = 1.2
@export var y_offset: float = 0.0
@export_range(0.0, 70.0, 0.5) var max_slope_degrees: float = 28.0
@export var random_yaw: bool = true
@export_range(0.0, 1.0, 0.01) var min_wellstone: float = 0.0
@export_range(0.0, 1.0, 0.01) var max_wellstone: float = 1.0
@export_range(0.0, 1.0, 0.01) var min_moisture: float = 0.0
@export_range(0.0, 1.0, 0.01) var max_moisture: float = 1.0
@export var max_per_chunk: int = 16
@export var tint: Color = Color(1, 1, 1, 1)
@export var override_emission: bool = false
@export var emission_color: Color = Color(0, 0, 0, 1)
@export var emission_energy: float = 0.0
## Empty: emission override applies to every mesh. Otherwise only these node names.
@export var emission_surface_names: PackedStringArray = PackedStringArray()
## Cheap stand-in collider. The visual stays a MultiMesh; one shape is placed per instance.
@export_enum("none", "cylinder", "sphere", "box") var collision_kind: String = "none"
@export var collision_radius: float = 0.3
@export var collision_height: float = 1.0
