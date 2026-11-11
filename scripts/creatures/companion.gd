extends Node3D

## The player's first raised creature. There is no separate companion species:
## this placeholder is that creature, small and generic, until its .glb arrives.
## It has no collision so it cannot shove the player.

@export var follow_distance: float = 1.75
@export var side_distance: float = 0.9
@export var catchup: float = 4.0
@export var visual_scene: PackedScene

var _bob: float = 0.0


func _enter_tree() -> void:
	add_to_group("companion")


func _ready() -> void:
	CreatureVisual.apply_override(self, visual_scene)
	var visual := get_node_or_null("VisualRoot")
	if visual != null:
		ToonMaterial.apply_node(visual)


func snap_to(player: Node3D) -> void:
	if player == null:
		return
	global_position = _destination(player)


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var destination := _destination(player)
	var next := global_position.lerp(destination, 1.0 - exp(-catchup * delta))
	var ground := _ground_height(next.x, next.z)
	_bob += delta
	var speed := 0.0
	if player is CharacterBody3D:
		speed = Vector2(player.velocity.x, player.velocity.z).length()
	var moving := speed > 0.35
	var bob := sin(_bob * (7.5 if moving else 2.2)) * (0.035 if moving else 0.012)
	global_position = Vector3(next.x, ground + bob, next.z)
	_turn_toward(player.global_position)
	_swing_legs(moving)


func _destination(player: Node3D) -> Vector3:
	var forward := Vector3(0, 0, -1)
	if "facing" in player:
		forward = player.facing
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		forward = Vector3(0, 0, -1)
	forward = forward.normalized()
	var right := forward.cross(Vector3.UP).normalized()
	var pos := player.global_position - forward * follow_distance + right * side_distance
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
	if flat.length_squared() < 0.04:
		return
	look_at(global_position + flat.normalized(), Vector3.UP)


func _swing_legs(moving: bool) -> void:
	var root := get_node_or_null("VisualRoot/Placeholder")
	if root == null or not root.visible:
		return
	var swing := sin(_bob * 8.0) * 0.45 if moving else 0.0
	_set_leg(root, "LegFL", swing)
	_set_leg(root, "LegBR", swing)
	_set_leg(root, "LegFR", -swing)
	_set_leg(root, "LegBL", -swing)


func _set_leg(root: Node, leg_name: String, angle: float) -> void:
	var leg := root.get_node_or_null(leg_name) as Node3D
	if leg == null:
		return
	leg.rotation.x = angle
