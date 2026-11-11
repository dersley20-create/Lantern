extends Node3D

## Boots into the world. The only interface is the touch stick, and only while
## a finger is down. There are no stat bars.

@onready var _world: WorldStreamer = $World
@onready var _player: CharacterBody3D = $Player
@onready var _companion: Node3D = $FirstRaised
@onready var _camera: Node3D = $FollowCamera

var _started: bool = false
var _shot_path: String = ""
var _shot_frames: int = 0
var _shot_started: bool = false


func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-48, 36, 0)
	$Fill.rotation_degrees = Vector3(-22, -142, 0)
	_player.follow_camera = _camera
	_shot_path = OS.get_environment("LANTERN_SCREENSHOT")
	_try_start()


func _process(_delta: float) -> void:
	if not _started:
		_try_start()
	_tick_screenshot()


func _try_start() -> void:
	if _started or _world == null or not _world.home_ready:
		return
	_player.global_position = _world.spawn_position
	_player.velocity = Vector3.ZERO
	if _companion.has_method("snap_to"):
		_companion.snap_to(_player)
	if not _shot_path.is_empty() and _camera.has_method("frame_companion"):
		_camera.frame_companion()
	elif _camera.has_method("snap"):
		_camera.snap()
	_player.enable_play()
	_started = true


func _tick_screenshot() -> void:
	if _shot_path.is_empty() or _shot_started or not _started:
		return
	_shot_frames += 1
	var ring_ready := _world.is_ring_ready()
	if ring_ready and _shot_frames > 48:
		_shot_started = true
		_capture_screenshot()
	elif _shot_frames > 900:
		_shot_started = true
		_capture_screenshot()


func _capture_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image.get_format() != Image.FORMAT_RGB8 and image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGB8)
	var directory := _shot_path.get_base_dir()
	if not directory.is_empty():
		DirAccess.make_dir_recursive_absolute(directory)
	var err := image.save_png(_shot_path)
	print("SCREENSHOT err=%s path=%s size=%sx%s" % [err, _shot_path, image.get_width(), image.get_height()])
	if OS.get_environment("LANTERN_SCREENSHOT_QUIT") == "1":
		get_tree().quit()
