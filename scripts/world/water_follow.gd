class_name WaterSheet
extends MeshInstance3D

## A single unshaded sheet. It follows the player on XZ.
## The walkable shelf sits above the collision sea floor, so the visible
## surface is lifted until it meets the Saltglass sand. Wading stays on the terrain.

const SURFACE_LIFT := 2.45

var _sea_level: float = 9.65
var _configured: bool = false


func _ready() -> void:
	var quality := VisualQuality.load_default()
	if material_override is ShaderMaterial:
		(material_override as ShaderMaterial).set_shader_parameter("use_shore_foam", quality.shore_foam())


func _process(_delta: float) -> void:
	if not _configured:
		var world := get_tree().get_first_node_in_group("world")
		if world != null and world.get("config") != null:
			_sea_level = float(world.config.sea_level) + SURFACE_LIFT
			_configured = true
	var x := 0.0
	var z := 0.0
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		x = player.global_position.x
		z = player.global_position.z
	global_position = Vector3(x, _sea_level, z)
