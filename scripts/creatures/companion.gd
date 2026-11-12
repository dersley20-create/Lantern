extends Node3D

## Placeholder companion until the Vuena cat, fox, or owl arrives.
## Cactoro and Mushnub are wild Nestkin, not this slot. Pyreleaf stays in
## the repo and is unused. Target height is about 0.6 m. No collision.

@export var follow_distance: float = 0.7
@export var side_distance: float = 0.55
@export var catchup: float = 4.2

var _bob: float = 0.0


func _enter_tree() -> void:
	add_to_group("companion")


func _ready() -> void:
	var root := get_node_or_null("VisualRoot")
	if root != null:
		ToonMaterial.apply_node(root)


func snap_to(body: Node3D) -> void:
	if body == null:
		return
	global_position = _destination(body)


func _process(delta: float) -> void:
	var body := get_tree().get_first_node_in_group("player") as Node3D
	if body == null:
		return
	var destination := _destination(body)
	var next := global_position.lerp(destination, 1.0 - exp(-catchup * delta))
	var ground := _ground_height(next.x, next.z)
	_bob += delta
	var speed := 0.0
	if body is CharacterBody3D:
		speed = Vector2(body.velocity.x, body.velocity.z).length()
	var hop := absf(sin(_bob * 10.0)) * 0.035 if speed > 0.35 else 0.0
	global_position = Vector3(next.x, ground + hop, next.z)
	if speed > 0.35:
		var travel := destination - global_position
		travel.y = 0.0
		if travel.length_squared() > 0.02:
			_turn_toward(global_position + travel.normalized())
	else:
		_turn_toward(body.global_position)


func _destination(body: Node3D) -> Vector3:
	var forward := Vector3(0, 0, -1)
	if "facing" in body:
		forward = body.facing
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		forward = Vector3(0, 0, -1)
	forward = forward.normalized()
	var right := forward.cross(Vector3.UP).normalized()
	var pos := body.global_position - forward * follow_distance + right * side_distance
	pos.y = _ground_height(pos.x, pos.z)
	return pos


func _ground_height(x: float, z: float) -> float:
	var world := get_tree().get_first_node_in_group("world")
	if world != null and world.has_method("sample_height"):
		return world.sample_height(x, z)
	return global_position.y


func _turn_toward(target: Vector3) -> void:
	var flat := target - global_position
	flat.y = 0.0
	if flat.length_squared() < 0.02:
		return
	look_at(global_position + flat.normalized(), Vector3.UP)
