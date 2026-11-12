extends CharacterBody3D

## Placeholder walker. Movement is camera-relative so WASD and the left-hand
## stick agree with the landscape follow camera.
## Collision is a capsule; the visible mesh is disposable.

@export var move_speed: float = 4.6
@export var acceleration: float = 16.0
@export var gravity: float = 30.0
@export var visual_scene: PackedScene

var facing: Vector3 = Vector3(0, 0, -1)
var follow_camera: Node3D
var scripted_wish: Vector3 = Vector3.ZERO

var _playing: bool = false


func _enter_tree() -> void:
	add_to_group("player")


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(56.0)
	floor_stop_on_slope = true
	safe_margin = 0.08
	CreatureVisual.apply_override(self, visual_scene)
	var visual := get_node_or_null("VisualRoot")
	if visual != null:
		ToonMaterial.apply_node(visual)
	set_physics_process(false)


func enable_play() -> void:
	_playing = true
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not _playing:
		return
	var wish := _wish_direction()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var target := wish * move_speed
	var rate := acceleration if wish.length_squared() > 0.0001 else acceleration * 1.4
	horizontal = horizontal.move_toward(target, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	if wish.length_squared() > 0.01:
		facing = wish.normalized()
		_face(facing)
	if global_position.y < -30.0:
		_recover()


func _wish_direction() -> Vector3:
	if scripted_wish.length_squared() > 0.0004:
		return scripted_wish
	var input := Vector2.ZERO
	input.x += float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	input.x += float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT))
	input.y += float(Input.is_physical_key_pressed(KEY_W)) - float(Input.is_physical_key_pressed(KEY_S))
	input.y += float(Input.is_physical_key_pressed(KEY_UP)) - float(Input.is_physical_key_pressed(KEY_DOWN))
	var touch := get_tree().get_first_node_in_group("touch_controls")
	if touch != null:
		input += touch.move_vector
	if input.length() > 1.0:
		input = input.normalized()
	if input.length_squared() < 0.0004:
		return Vector3.ZERO
	var forward := Vector3(0, 0, -1)
	var right := Vector3(1, 0, 0)
	if follow_camera != null and follow_camera.has_method("flat_axes"):
		var axes: Dictionary = follow_camera.flat_axes()
		forward = axes.forward
		right = axes.right
	var direction := right * input.x + forward * input.y
	if direction.length() > 1.0:
		direction = direction.normalized()
	return direction


func _face(direction: Vector3) -> void:
	var root := get_node_or_null("VisualRoot") as Node3D
	if root == null:
		return
	var look_target := global_position + direction
	look_target.y = root.global_position.y
	if root.global_position.distance_squared_to(look_target) < 0.0001:
		return
	root.look_at(look_target, Vector3.UP)


func _recover() -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world != null and world.has_method("sample_height"):
		global_position.y = world.sample_height(global_position.x, global_position.z) + 1.2
	velocity = Vector3.ZERO
