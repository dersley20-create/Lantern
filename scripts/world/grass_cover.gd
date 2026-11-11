class_name GrassCover
extends RefCounted

## Crossed cards for Hearthvale. One mesh, one MultiMesh per near chunk.

static var _mesh: ArrayMesh
static var _material: ShaderMaterial


static func attach(chunk: Node3D, params: TerrainParams, noises: Dictionary, count: int, wind_scale: float) -> void:
	if count <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = TerrainSampler.hash_chunk(params.world_seed, chunk.coord.x, chunk.coord.y) + 91
	var placed: Array[Transform3D] = []
	var origin_x := chunk.position.x
	var origin_z := chunk.position.z
	var guard := 0
	while placed.size() < count and guard < count * 4:
		guard += 1
		var x := origin_x + rng.randf() * params.chunk_size
		var z := origin_z + rng.randf() * params.chunk_size
		var sample := TerrainSampler.sample_at(params, noises, x, z)
		if sample.biome != BiomeIds.HEARTHVALE:
			continue
		if TerrainSampler.slope_at(params, noises, x, z) > 0.42:
			continue
		var yaw := rng.randf() * TAU
		var scale := rng.randf_range(0.9, 1.55)
		var basis := Basis(Vector3.UP, yaw).scaled(Vector3(scale, scale, scale))
		placed.append(Transform3D(basis, Vector3(x - origin_x, float(sample.height), z - origin_z)))
	if placed.is_empty():
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = _shared_mesh()
	multi.instance_count = placed.size()
	multi.custom_aabb = AABB(Vector3(-1, -2, -1), Vector3(params.chunk_size + 2.0, 6.0, params.chunk_size + 2.0))
	for i in placed.size():
		multi.set_instance_transform(i, placed[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = "Grass"
	instance.multimesh = multi
	instance.material_override = _shared_material(wind_scale)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	chunk.add_child(instance)


static func _shared_mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var built := _cards()
	var vertices: PackedVector3Array = built.vertices
	var normals: PackedVector3Array = built.normals
	var colors: PackedColorArray = built.colors
	var indices: PackedInt32Array = built.indices
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	_mesh = ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _mesh


static func _cards() -> Dictionary:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var root := Color(0.18, 0.4, 0.12, 1.0)
	var tip := Color(0.46, 0.7, 0.26, 1.0)
	for i in 3:
		var yaw := float(i) * TAU / 3.0
		var basis := Basis(Vector3.UP, yaw)
		var shift := basis * Vector3(0.1, 0.0, 0.04)
		var height := 0.5 + float(i) * 0.1
		var blade := _blade(basis, shift, height, 0.18, root, tip)
		vertices.append_array(blade.vertices)
		normals.append_array(blade.normals)
		colors.append_array(blade.colors)
		var base := vertices.size() - 4
		indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
		var side := basis.rotated(Vector3.UP, PI * 0.5)
		blade = _blade(side, shift, height * 0.82, 0.12, root, tip)
		vertices.append_array(blade.vertices)
		normals.append_array(blade.normals)
		colors.append_array(blade.colors)
		base = vertices.size() - 4
		indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	return {"vertices": vertices, "normals": normals, "colors": colors, "indices": indices}


static func _blade(basis: Basis, shift: Vector3, height: float, lean: float, root: Color, tip: Color) -> Dictionary:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var corners: Array[Vector3] = [
		Vector3(-0.1, 0.0, 0.0),
		Vector3(0.1, 0.0, 0.0),
		Vector3(0.03, height, lean),
		Vector3(-0.03, height, lean),
	]
	var corner_colors: Array[Color] = [root, root, tip, tip]
	for i in corners.size():
		vertices.append(basis * corners[i] + shift)
		normals.append((basis * Vector3(0.0, 0.42, 1.0)).normalized())
		colors.append(corner_colors[i])
	return {"vertices": vertices, "normals": normals, "colors": colors}


static func _shared_material(wind_scale: float) -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load("res://assets/shaders/toon.gdshader")
		_material.set_shader_parameter("albedo_color", Color(1.0, 1.0, 1.0, 1.0))
		_material.set_shader_parameter("use_vertex_color", true)
		_material.set_shader_parameter("rim_strength", 0.04)
		_material.set_shader_parameter("ambient_level", 0.34)
		_material.set_shader_parameter("light_neutral", 0.72)
		_material.set_shader_parameter("shadow_tint", Vector3(0.62, 0.74, 0.55))
	_material.set_shader_parameter("wind_strength", 0.2 * wind_scale)
	return _material
