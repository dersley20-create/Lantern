class_name ShoreFoam
extends RefCounted

## White discs along the contour where the terrain crosses the water sheet.
## A depth-texture edge disappears on renderers that do not expose one.

const FOAM_SHADER := "res://assets/shaders/foam.gdshader"

static var _mesh: ArrayMesh
static var _material: ShaderMaterial


static func attach(chunk: Node3D, params: TerrainParams, noises: Dictionary, water_y: float) -> void:
	var origin_x := chunk.position.x
	var origin_z := chunk.position.z
	var step := 2.0
	var placed: Array[Transform3D] = []
	var z := 0.0
	while z < params.chunk_size:
		var x := 0.0
		while x < params.chunk_size:
			var h := TerrainSampler.height_at(params, noises, origin_x + x, origin_z + z)
			var hx := TerrainSampler.height_at(params, noises, origin_x + x + step, origin_z + z)
			var hz := TerrainSampler.height_at(params, noises, origin_x + x, origin_z + z + step)
			_crossing(placed, x, z, step, 0.0, h, hx, water_y)
			_crossing(placed, x, z, 0.0, step, h, hz, water_y)
			x += step
		z += step
	if placed.is_empty():
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = _shared_mesh()
	multi.instance_count = placed.size()
	multi.custom_aabb = AABB(Vector3(-2.0, water_y - 2.0, -2.0), Vector3(params.chunk_size + 4.0, 6.0, params.chunk_size + 4.0))
	for i in placed.size():
		multi.set_instance_transform(i, placed[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = "ShoreFoam"
	instance.multimesh = multi
	instance.material_override = _shared_material()
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	chunk.add_child(instance)


static func _crossing(placed: Array[Transform3D], x: float, z: float, dx: float, dz: float, h0: float, h1: float, water_y: float) -> void:
	var span := h1 - h0
	if absf(span) < 0.0001:
		return
	if (h0 - water_y) * (h1 - water_y) > 0.0:
		return
	var t := clampf((water_y - h0) / span, 0.0, 1.0)
	var px := x + dx * t
	var pz := z + dz * t
	var jitter := float(absi(int(px * 13.0) + int(pz * 7.0)) % 5)
	var scale := 0.85 + jitter * 0.14
	var basis := Basis.from_scale(Vector3(scale, 1.0, scale))
	placed.append(Transform3D(basis, Vector3(px, water_y + 0.08, pz)))


static func _shared_mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	vertices.append(Vector3.ZERO)
	normals.append(Vector3.UP)
	uvs.append(Vector2(0.5, 0.5))
	var segments := 8
	for i in segments:
		var angle := float(i) / float(segments) * TAU
		vertices.append(Vector3(cos(angle), 0.0, sin(angle)))
		normals.append(Vector3.UP)
		uvs.append(Vector2(cos(angle) * 0.5 + 0.5, sin(angle) * 0.5 + 0.5))
		var next := 1 if i == segments - 1 else i + 2
		indices.append_array([0, i + 1, next])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	_mesh = ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _mesh


static func _shared_material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load(FOAM_SHADER)
		_material.set_shader_parameter("albedo_color", Color(0.97, 0.98, 0.95, 0.9))
	return _material
