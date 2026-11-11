class_name GrassCover
extends RefCounted

## Dense Hearthvale pasture from the artist clumps. One MultiMesh per
## material, with the toon wind on the blades. Procedural cards are gone.

const KINDS := {
	"small": ["res://assets/models/props/hearthvale/hearthvale_grass_clump_small.glb", 0.12],
	"medium": ["res://assets/models/props/hearthvale/hearthvale_grass_clump.glb", 0.16],
	"tall": ["res://assets/models/props/hearthvale/hearthvale_grass_clump_tall.glb", 0.22],
	"cover": ["res://assets/models/props/hearthvale/hearthvale_ground_cover.glb", 0.05],
}

static var _parts: Dictionary = {}


static func attach(chunk: Node3D, params: TerrainParams, noises: Dictionary, mix: Dictionary, wind_scale: float, blockers: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = TerrainSampler.hash_chunk(params.world_seed, chunk.coord.x, chunk.coord.y) + 91
	var order: Array[String] = ["small", "medium", "tall", "cover"]
	for kind in order:
		var count := int(mix.get(kind, 0))
		if count <= 0 or wind_scale < 0.0:
			continue
		var placed := _scatter(rng, params, noises, chunk, count, kind, blockers)
		if placed.is_empty():
			continue
		var wind := float(KINDS[kind][1]) * wind_scale
		_add_meshes(chunk, placed, kind, wind, params.chunk_size)


static func _scatter(rng: RandomNumberGenerator, params: TerrainParams, noises: Dictionary, chunk: Node3D, count: int, kind: String, blockers: Array) -> Array[Transform3D]:
	var placed: Array[Transform3D] = []
	var origin_x := chunk.position.x
	var origin_z := chunk.position.z
	var guard := 0
	var limit := count * 5
	while placed.size() < count and guard < limit:
		guard += 1
		var x := origin_x + rng.randf() * params.chunk_size
		var z := origin_z + rng.randf() * params.chunk_size
		if _blocked(x, z, blockers):
			continue
		var sample := TerrainSampler.sample_at(params, noises, x, z)
		if sample.biome != BiomeIds.HEARTHVALE:
			continue
		if TerrainSampler.slope_at(params, noises, x, z) > 0.42:
			continue
		var yaw := rng.randf() * TAU
		var scale := rng.randf_range(0.88, 1.18)
		if kind == "cover":
			scale = rng.randf_range(0.9, 1.15)
		var basis := Basis(Vector3.UP, yaw).scaled(Vector3(scale, scale, scale))
		placed.append(Transform3D(basis, Vector3(x - origin_x, float(sample.height), z - origin_z)))
	return placed


static func _blocked(x: float, z: float, blockers: Array) -> bool:
	for spot in blockers:
		var dx := x - float(spot.x)
		var dz := z - float(spot.z)
		var radius := float(spot.r)
		if dx * dx + dz * dz < radius * radius:
			return true
	return false


static func _add_meshes(chunk: Node3D, placed: Array[Transform3D], kind: String, wind: float, chunk_size: float) -> void:
	var parts: Array = _parts_for(kind, wind)
	for part in parts:
		var mesh: Mesh = part.mesh
		if mesh == null:
			continue
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh
		multi.instance_count = placed.size()
		multi.custom_aabb = AABB(Vector3(-2, -2, -2), Vector3(chunk_size + 4.0, 8.0, chunk_size + 4.0))
		var local: Transform3D = part.local
		for i in placed.size():
			multi.set_instance_transform(i, placed[i] * local)
		var instance := MultiMeshInstance3D.new()
		instance.name = "Grass_%s" % kind
		instance.multimesh = multi
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		chunk.add_child(instance)


static func _parts_for(kind: String, wind: float) -> Array:
	if _parts.has(kind):
		return _parts[kind]
	var packed := load(String(KINDS[kind][0])) as PackedScene
	if packed == null:
		_parts[kind] = []
		return []
	var inst := packed.instantiate()
	var parts: Array = []
	_collect(inst, Transform3D.IDENTITY, wind, parts)
	inst.free()
	_parts[kind] = parts
	return parts


static func _collect(node: Node, parent_xf: Transform3D, wind: float, parts: Array) -> void:
	var xf := parent_xf
	if node is Node3D:
		xf = parent_xf * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			var baked: Mesh = mesh_instance.mesh.duplicate()
			for surface_index in baked.get_surface_count():
				var source := mesh_instance.get_surface_override_material(surface_index)
				if source == null:
					source = mesh_instance.mesh.surface_get_material(surface_index)
				baked.surface_set_material(surface_index, ToonMaterial.from_source(source, Color.WHITE, null, "", wind))
			parts.append({"mesh": baked, "local": xf})
	for child in node.get_children():
		_collect(child, xf, wind, parts)
