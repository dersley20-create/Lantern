extends Node3D

## High, angled follow camera framed for landscape.
## Pitch stays in the Diablo range; scroll and pinch only change distance.

@export var pitch_degrees: float = 55.0
@export var distance: float = 16.5
@export var min_distance: float = 11.0
@export var max_distance: float = 23.0
@export var follow_sharpness: float = 4.0
@export var zoom_sharpness: float = 8.0
@export var yaw_degrees: float = 32.0
@export var yaw_speed_degrees: float = 70.0
@export var look_height: float = 1.15
@export var look_ahead: float = 1.8
@export var fov: float = 52.0

var _yaw: float = 0.0
var _yaw_target: float = 0.0
var _distance: float = 16.5
var _distance_target: float = 16.5
var _anchor: Vector3 = Vector3.ZERO
var _snapped: bool = false
var _camera: Camera3D


func _enter_tree() -> void:
	add_to_group("follow_camera")


func _ready() -> void:
	_camera = get_node_or_null("Camera3D") as Camera3D
	if _camera == null:
		_camera = Camera3D.new()
		_camera.name = "Camera3D"
		add_child(_camera)
	_camera.current = true
	_camera.fov = fov
	_camera.near = 0.2
	_camera.far = 260.0
	_yaw = deg_to_rad(yaw_degrees)
	_yaw_target = _yaw
	_distance = clampf(distance, min_distance, max_distance)
	_distance_target = _distance


## Pulls in for a companion portrait. Gameplay zoom limits stay as exported.
func frame_companion() -> void:
	min_distance = 2.8
	pitch_degrees = 42.0
	look_height = 0.5
	look_ahead = -0.15
	fov = 36.0
	_distance = 5.4
	_distance_target = 5.4
	if _camera != null:
		_camera.fov = fov
		_camera.near = 0.05
	snap()


## Frames a pair of landmarks sitting about 8 m ahead of the player.
func frame_pair() -> void:
	min_distance = 8.0
	pitch_degrees = 42.0
	look_height = 1.5
	look_ahead = 8.0
	fov = 48.0
	_distance = 14.0
	_distance_target = 14.0
	if _camera != null:
		_camera.fov = fov
	snap()


func snap() -> void:
	var player := _player()
	if player == null:
		return
	_anchor = player.global_position
	_snapped = true
	_apply(1.0)


func flat_axes() -> Dictionary:
	return {
		"forward": Vector3(-sin(_yaw), 0.0, -cos(_yaw)),
		"right": Vector3(cos(_yaw), 0.0, -sin(_yaw)),
	}


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance_target -= 1.15
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance_target += 1.15
		_distance_target = clampf(_distance_target, min_distance, max_distance)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0:
		_yaw_target -= event.relative.x * 0.005
	elif event is InputEventMagnifyGesture:
		# Trackpad pinch. factor > 1 magnifies, which brings the camera in.
		_distance_target += (1.0 - event.factor) * 16.0
		_distance_target = clampf(_distance_target, min_distance, max_distance)


func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_Q):
		_yaw_target += deg_to_rad(yaw_speed_degrees) * delta
	if Input.is_physical_key_pressed(KEY_E):
		_yaw_target -= deg_to_rad(yaw_speed_degrees) * delta
	if Input.is_physical_key_pressed(KEY_MINUS) or Input.is_physical_key_pressed(KEY_KP_SUBTRACT):
		_distance_target = clampf(_distance_target + 10.0 * delta, min_distance, max_distance)
	if Input.is_physical_key_pressed(KEY_EQUAL) or Input.is_physical_key_pressed(KEY_KP_ADD):
		_distance_target = clampf(_distance_target - 10.0 * delta, min_distance, max_distance)
	var touch := get_tree().get_first_node_in_group("touch_controls")
	if touch != null:
		_yaw_target += float(touch.yaw_delta)
		touch.yaw_delta = 0.0
		_distance_target = clampf(_distance_target + float(touch.zoom_delta), min_distance, max_distance)
		touch.zoom_delta = 0.0
	if not _snapped:
		snap()
		return
	var blend := 1.0 - exp(-follow_sharpness * delta)
	var player := _player()
	if player != null:
		_anchor = _anchor.lerp(player.global_position, blend)
	_yaw = lerp_angle(_yaw, _yaw_target, 1.0 - exp(-10.0 * delta))
	_distance = lerpf(_distance, _distance_target, 1.0 - exp(-zoom_sharpness * delta))
	_apply(delta)


func _apply(_delta: float) -> void:
	if _camera == null:
		return
	var axes := flat_axes()
	var forward: Vector3 = axes.forward
	var look := _anchor + Vector3(0.0, look_height, 0.0) + forward * look_ahead
	var pitch := deg_to_rad(clampf(pitch_degrees, 40.0, 70.0))
	var back := -forward
	var offset := back * (_distance * cos(pitch)) + Vector3.UP * (_distance * sin(pitch))
	var desired := look + offset
	_camera.global_position = _resolve_collision(look, desired)
	if _camera.global_position.distance_squared_to(look) > 0.04:
		_camera.look_at(look, Vector3.UP)


func _resolve_collision(from: Vector3, to: Vector3) -> Vector3:
	var player := _player()
	if player == null or player.get_world_3d() == null:
		return to
	var space := player.get_world_3d().direct_space_state
	if space == null:
		return to
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return to
	return hit.position + (hit.normal as Vector3) * 0.4


func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D
