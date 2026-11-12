class_name VillageLayout
extends RefCounted

## Bramblecross, hand-placed on the Hearthvale spawn.
## The player stands just outside grandmother's door. The well is the centre.
## Doors face local -Z (the artist's +Y front, after the glTF axis swap).

const MODEL := "res://assets/models/village/%s.glb"
const YAW := 0.5585053606381855

static var enabled: bool = false
static var origin := Vector2.ZERO
static var axis_f := Vector2(0.0, -1.0)
static var axis_r := Vector2(1.0, 0.0)
static var pad_y: float = 0.0
static var flat_min_f: float = -3.0
static var flat_max_f: float = 26.0
static var flat_half_r: float = 16.0
static var blend_m: float = 6.0
static var _blocks: Array = []


static func configure(spawn: Vector3) -> void:
	var yaw := YAW
	axis_f = Vector2(-sin(yaw), -cos(yaw))
	axis_r = Vector2(cos(yaw), -sin(yaw))
	origin = Vector2(spawn.x, spawn.z)
	pad_y = spawn.y - 0.2
	_blocks.clear()
	enabled = true


static func blend(x: float, z: float, height: float) -> float:
	if not enabled:
		return height
	var local := _local(x, z)
	var df := 0.0
	if local.x < flat_min_f:
		df = flat_min_f - local.x
	elif local.x > flat_max_f:
		df = local.x - flat_max_f
	var dr := maxf(0.0, absf(local.y) - flat_half_r)
	var dist := Vector2(df, dr).length()
	if dist >= blend_m:
		return height
	var weight := 1.0 - smoothstep(0.0, blend_m, dist)
	return lerpf(height, pad_y, weight)


static func blocks(x: float, z: float) -> bool:
	if not enabled:
		return false
	var point := Vector2(x, z)
	for spot in _blocks:
		if point.distance_to(Vector2(float(spot.x), float(spot.z))) < float(spot.r):
			return true
	return false


static func inside_pad(x: float, z: float) -> bool:
	if not enabled:
		return false
	var local := _local(x, z)
	return local.x >= flat_min_f and local.x <= flat_max_f and absf(local.y) <= flat_half_r


static func cull_props(props: Dictionary, origin_x: float, origin_z: float) -> Dictionary:
	if not enabled or props.is_empty():
		return props
	var kept := {}
	for key in props.keys():
		var surviving: Array = []
		for item in props[key]:
			var xf: Transform3D = item
			if not blocks(origin_x + xf.origin.x, origin_z + xf.origin.z):
				surviving.append(xf)
		if not surviving.is_empty():
			kept[key] = surviving
	return kept


static func attach(chunk: Node3D, height_at: Callable) -> void:
	if not enabled:
		return
	var root := Node3D.new()
	root.name = "Bramblecross"
	root.set_script(load("res://scripts/world/village_glow.gd"))
	chunk.add_child(root)
	var placed := 0
	var player := _world(0.0, 0.0)
	var forward := Vector3(axis_f.x, 0.0, axis_f.y)
	var right := Vector3(axis_r.x, 0.0, axis_r.y)
	var well := player + forward * 12.0
	placed += int(_house(root, chunk, height_at, "village_grandmother_cottage", player + forward * 4.35, player, Vector3(6.8, 2.6, 5.4), 4.6))
	placed += int(_house(root, chunk, height_at, "village_cottage_a", well + right * 9.0, well, Vector3(4.0, 2.4, 4.8), 3.6))
	placed += int(_house(root, chunk, height_at, "village_cottage_b", well - right * 9.2, well, Vector3(5.3, 2.4, 4.9), 3.8))
	placed += int(_house(root, chunk, height_at, "village_cottage_c", well + forward * 8.2, well, Vector3(4.5, 2.4, 4.5), 3.5))
	placed += int(_prop(root, chunk, height_at, "village_well", well, well + forward, "cylinder", 0.75, 1.3, 1.5))
	placed += int(_prop(root, chunk, height_at, "village_cart", well + right * 3.4 - forward * 1.2, well, "box", 0.7, 1.1, 1.8))
	placed += int(_prop(root, chunk, height_at, "village_garden_bed", player + forward * 3.2 + right * 4.8, player, "box", 0.9, 0.45, 1.3))
	placed += int(_prop(root, chunk, height_at, "village_garden_bed", player + forward * 5.4 - right * 4.6, well, "box", 0.9, 0.45, 1.3))
	placed += int(_prop(root, chunk, height_at, "village_garden_bed", well - right * 5.4 - forward * 1.5, well, "box", 0.9, 0.45, 1.3))
	for step in [3.0, 6.4, 9.6]:
		placed += int(_lamp(root, chunk, height_at, player + forward * step + right * 1.7, player + forward * step))
		placed += int(_lamp(root, chunk, height_at, player + forward * step - right * 1.7, player + forward * step))
	if placed == 0:
		root.queue_free()


static func _house(root: Node3D, chunk: Node3D, height_at: Callable, file_name: String, at: Vector3, face: Vector3, box_size: Vector3, block_radius: float) -> bool:
	return _prop(root, chunk, height_at, file_name, at, face, "box", 0.0, box_size.y, block_radius, box_size)


static func _lamp(root: Node3D, chunk: Node3D, height_at: Callable, at: Vector3, face: Vector3) -> bool:
	return _prop(root, chunk, height_at, "village_lantern_post", at, face, "cylinder", 0.16, 2.2, 0.0)


static func _prop(root: Node3D, chunk: Node3D, height_at: Callable, file_name: String, at: Vector3, face: Vector3, collision_kind: String, radius: float, height: float, block_radius: float, box_size: Vector3 = Vector3.ZERO) -> bool:
	var packed := load(MODEL % file_name) as PackedScene
	if packed == null:
		return false
	_remember_block(at.x, at.z, block_radius)
	if not _in_chunk(chunk, at.x, at.z):
		return false
	var node := packed.instantiate() as Node3D
	if node == null:
		return false
	_style(node, root)
	root.add_child(node)
	var ground: float = height_at.call(at.x, at.z)
	node.position = Vector3(at.x - chunk.position.x, ground, at.z - chunk.position.z)
	var look := Vector3(face.x, ground, face.z)
	if node.global_position.distance_squared_to(look) > 0.05:
		node.look_at(look, Vector3.UP)
	_collide(node, collision_kind, radius, height, box_size)
	if file_name.ends_with("lantern_post") or file_name.ends_with("grandmother_cottage"):
		var glow := OmniLight3D.new()
		glow.name = "WarmLamp"
		glow.position = Vector3(0.0, 2.1, -1.6) if file_name.ends_with("grandmother_cottage") else Vector3(0.0, 2.35, -0.2)
		glow.light_color = Color(1.0, 0.78, 0.42)
		glow.light_energy = 0.22
		glow.shadow_enabled = false
		glow.omni_range = 4.2 if file_name.ends_with("lantern_post") else 5.5
		node.add_child(glow)
		if root.has_method("remember_lamp"):
			root.remember_lamp(glow)
	return true


static func _remember_block(x: float, z: float, radius: float) -> void:
	if radius <= 0.0:
		return
	for spot in _blocks:
		if absf(float(spot.x) - x) < 0.05 and absf(float(spot.z) - z) < 0.05:
			return
	_blocks.append({"x": x, "z": z, "r": radius})


static func _style(node: Node, host: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			for index in mesh_instance.mesh.get_surface_count():
				var source := mesh_instance.get_surface_override_material(index)
				if source == null:
					source = mesh_instance.mesh.surface_get_material(index)
				var mat := ToonMaterial.from_source(source)
				var material_name := String(source.resource_name) if source != null else ""
				if material_name == "HV_Window" or material_name == "HV_Lamp":
					var base := float(mat.get_shader_parameter("emission_energy"))
					if base < 1.0:
						base = 1.8
					mat.set_meta("glow_base", base)
					if host.has_method("remember_glow"):
						host.remember_glow(mat)
				mesh_instance.set_surface_override_material(index, mat)
	for child in node.get_children():
		_style(child, host)


static func _collide(node: Node3D, collision_kind: String, radius: float, height: float, box_size: Vector3) -> void:
	if collision_kind == "" or collision_kind == "none":
		return
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape_node := CollisionShape3D.new()
	if collision_kind == "cylinder":
		var cylinder := CylinderShape3D.new()
		cylinder.radius = radius
		cylinder.height = height
		shape_node.shape = cylinder
		shape_node.position.y = height * 0.5
	else:
		var box := BoxShape3D.new()
		box.size = box_size if box_size != Vector3.ZERO else Vector3(radius * 2.0, height, radius * 2.0)
		shape_node.shape = box
		shape_node.position.y = box.size.y * 0.5
	body.add_child(shape_node)
	node.add_child(body)


static func _in_chunk(chunk: Node3D, x: float, z: float) -> bool:
	var size := 32.0
	return x >= chunk.position.x and x < chunk.position.x + size and z >= chunk.position.z and z < chunk.position.z + size


static func _world(forward_m: float, right_m: float) -> Vector3:
	return Vector3(origin.x, 0.0, origin.y) + Vector3(axis_f.x, 0.0, axis_f.y) * forward_m + Vector3(axis_r.x, 0.0, axis_r.y) * right_m


static func _local(x: float, z: float) -> Vector2:
	var delta := Vector2(x, z) - origin
	return Vector2(delta.dot(axis_f), delta.dot(axis_r))
