class_name FarmPlot
extends RefCounted

## A small fenced plot just ahead of the spawn point.
## Fence segments are the 2.0 m tile. Crop patches are the 2.0 m square.
## Built once for the spawn chunk, so it does not depend on scatter density.

const FENCE := "res://assets/models/props/hearthvale/hearthvale_fence.glb"
const CROP := "res://assets/models/props/hearthvale/hearthvale_crop_patch.glb"
const HAY := "res://assets/models/props/hearthvale/hearthvale_hay_bale.glb"


static func attach(chunk: Node3D, spawn: Vector3, height_at: Callable) -> void:
	var fence_scene := load(FENCE) as PackedScene
	var crop_scene := load(CROP) as PackedScene
	var hay_scene := load(HAY) as PackedScene
	if fence_scene == null or crop_scene == null or hay_scene == null:
		push_warning("Hearthvale farm models are missing; the spawn plot was skipped.")
		return
	var root := Node3D.new()
	root.name = "HearthvaleFarm"
	chunk.add_child(root)
	# Default camera yaw is 32 degrees. Place the plot in front of that view.
	var yaw := deg_to_rad(32.0)
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var center := Vector3(spawn.x, 0.0, spawn.z) + forward * 12.0
	var half := 4.0
	_side(root, fence_scene, chunk, height_at, center.x - half, center.z - half, true)
	_side(root, fence_scene, chunk, height_at, center.x - half, center.z + half, true)
	_side(root, fence_scene, chunk, height_at, center.x - half, center.z - half, false)
	_side(root, fence_scene, chunk, height_at, center.x + half, center.z - half, false)
	for gx in [-1.0, 1.0]:
		for gz in [-1.0, 1.0]:
			_prop(root, crop_scene, chunk, height_at, center.x + gx, center.z + gz, 0.0, "none", 0.0, 0.0)
	_prop(root, hay_scene, chunk, height_at, center.x + 5.4, center.z - 2.2, 0.4, "box", 0.48, 0.95)
	_prop(root, hay_scene, chunk, height_at, center.x + 5.6, center.z - 3.4, -0.5, "box", 0.48, 0.95)


static func _side(root: Node3D, scene: PackedScene, chunk: Node3D, height_at: Callable, origin_x: float, origin_z: float, along_x: bool) -> void:
	for step in 4:
		var x := origin_x + (float(step) * 2.0 + 1.0 if along_x else 0.0)
		var z := origin_z + (0.0 if along_x else float(step) * 2.0 + 1.0)
		var yaw := 0.0 if along_x else PI * 0.5
		_prop(root, scene, chunk, height_at, x, z, yaw, "box", 0.06, 1.22)


static func _prop(root: Node3D, scene: PackedScene, chunk: Node3D, height_at: Callable, x: float, z: float, yaw: float, collision_kind: String, radius: float, height: float) -> void:
	var node := scene.instantiate() as Node3D
	if node == null:
		return
	ToonMaterial.apply_node(node)
	root.add_child(node)
	var ground: float = height_at.call(x, z)
	node.position = Vector3(x - chunk.position.x, ground, z - chunk.position.z)
	node.rotation.y = yaw
	if collision_kind == "none":
		return
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape_node := CollisionShape3D.new()
	if collision_kind == "box":
		var box := BoxShape3D.new()
		# Fence tiles are 2 m along local X. Hay uses the same helper with a fatter radius.
		var length := 2.0 if radius < 0.2 else radius * 2.0
		var depth := 0.12 if radius < 0.2 else radius * 1.6
		box.size = Vector3(length, height, depth)
		shape_node.shape = box
		shape_node.position.y = height * 0.5
	body.add_child(shape_node)
	node.add_child(body)
