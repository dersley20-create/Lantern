extends MeshInstance3D

## A single unshaded sheet. It follows the player on XZ and sits at sea level,
## so the Saltglass shallows read as water without a simulated ocean.

var _sea_level: float = 7.2
var _configured: bool = false


func _process(_delta: float) -> void:
	if not _configured:
		var world := get_tree().get_first_node_in_group("world")
		if world != null and world.get("config") != null:
			_sea_level = float(world.config.sea_level)
			_configured = true
	var x := 0.0
	var z := 0.0
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		x = player.global_position.x
		z = player.global_position.z
	global_position = Vector3(x, _sea_level, z)
