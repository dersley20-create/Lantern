class_name HearthvaleWater
extends RefCounted

## Ponds and narrow streams on gentle Hearthvale ground.
## A pond is four bank curves around one water tile. A stream is a 2 m
## channel of straight banks, water tiles, and one stepping-stone crossing.
## The Saltglass sea keeps its own sheet and foam.

const BANK_CURVE := "res://assets/models/props/hearthvale/hearthvale_bank_curve.glb"
const BANK_STRAIGHT := "res://assets/models/props/hearthvale/hearthvale_bank_straight.glb"
const WATER_TILE := "res://assets/models/props/hearthvale/hearthvale_water_tile.glb"
const STONES := "res://assets/models/props/hearthvale/hearthvale_stepping_stones.glb"

const ARC_LOCAL := Vector3(-1.0, 0.0, 1.0)

static var _parts: Dictionary = {}


static func attach(chunk: Node3D, params: TerrainParams, noises: Dictionary, spawn: Vector3) -> Array:
	var built: Dictionary = _plan(params, noises, chunk.coord, chunk.position.x, chunk.position.z, spawn)
	var blockers: Array = built.blockers
	for kind in built.pieces.keys():
		var xforms: Array = built.pieces[kind]
		if xforms.is_empty():
			continue
		for part in _parts_for(kind):
			var mesh: Mesh = part.mesh
			if mesh == null:
				continue
			var multi := MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_3D
			multi.mesh = mesh
			multi.instance_count = xforms.size()
			multi.custom_aabb = AABB(Vector3(-4, -2, -4), Vector3(params.chunk_size + 8.0, 8.0, params.chunk_size + 8.0))
			var local: Transform3D = part.local
			for i in xforms.size():
				var placed: Transform3D = xforms[i]
				multi.set_instance_transform(i, placed * local)
			var instance := MultiMeshInstance3D.new()
			instance.name = "HearthWater_%s" % kind
			instance.multimesh = multi
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			chunk.add_child(instance)
	return blockers


static func nearest_stand(params: TerrainParams, noises: Dictionary, around: Vector3) -> Vector3:
	var yaw := deg_to_rad(32.0)
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var best := around
	var best_dist := 1.0e20
	var found := false
	var center := TerrainSampler.chunk_coord(around.x, around.z, params.chunk_size)
	for dz in range(-5, 6):
		for dx in range(-5, 6):
			var coord := Vector2i(center.x + dx, center.y + dz)
			var origin_x := float(coord.x) * params.chunk_size
			var origin_z := float(coord.y) * params.chunk_size
			var built: Dictionary = _plan(params, noises, coord, origin_x, origin_z, around)
			if built.pieces.is_empty() and built.blockers.is_empty():
				continue
			for spot in built.blockers:
				if float(spot.r) < 2.0:
					continue
				var at := Vector3(float(spot.x), 0.0, float(spot.z))
				var dist := Vector2(at.x, at.z).distance_to(Vector2(around.x, around.z))
				if dist < 8.0 or dist > best_dist:
					continue
				best_dist = dist
				var stand := at - forward * 11.0
				stand.y = TerrainSampler.height_at(params, noises, stand.x, stand.z) + 0.35
				best = stand
				found = true
	return best if found else around


static func pond_transforms(center: Vector3) -> Array[Transform3D]:
	var placed: Array[Transform3D] = []
	for i in 4:
		var basis := Basis(Vector3.UP, float(i) * PI * 0.5)
		var origin := center - basis * ARC_LOCAL
		origin.y = center.y
		placed.append(Transform3D(basis, origin))
	return placed


static func _plan(params: TerrainParams, noises: Dictionary, coord: Vector2i, origin_x: float, origin_z: float, spawn: Vector3) -> Dictionary:
	var empty := {"pieces": {}, "blockers": []}
	var roll := TerrainSampler.hash_chunk(params.world_seed, coord.x, coord.y) % 7
	var kind := ""
	if roll == 0:
		kind = "pond"
	elif roll <= 2:
		kind = "stream"
	else:
		return empty
	var spot := _flat_spot(params, noises, origin_x, origin_z, spawn)
	if spot.is_empty():
		return empty
	var center := Vector3(float(spot.x), float(spot.y), float(spot.z))
	var pieces := {}
	var blockers: Array = []
	if kind == "pond":
		pieces["curve"] = _local_many(pond_transforms(center), origin_x, origin_z)
		pieces["water"] = _local_many([Transform3D(Basis.IDENTITY, center)], origin_x, origin_z)
		blockers.append({"x": center.x, "z": center.z, "r": 2.7})
	else:
		var yaw := float(int(roll) % 4) * PI * 0.5
		var basis := Basis(Vector3.UP, yaw)
		var curves: Array[Transform3D] = []
		var waters: Array[Transform3D] = []
		for i in 3:
			var along := (float(i) - 1.0) * 2.0
			var water_at := center + basis * Vector3(along, 0.0, 0.0)
			water_at.y = center.y
			waters.append(Transform3D(basis, water_at))
			var north := center + basis * Vector3(along, 0.0, 1.5)
			north.y = center.y
			curves.append(Transform3D(basis, north))
			var south_basis := basis * Basis(Vector3.UP, PI)
			var south := center + basis * Vector3(along, 0.0, -1.5)
			south.y = center.y
			curves.append(Transform3D(south_basis, south))
			blockers.append({"x": water_at.x, "z": water_at.z, "r": 2.3})
		var stones_basis := basis * Basis(Vector3.UP, PI * 0.5)
		pieces["straight"] = _local_many(curves, origin_x, origin_z)
		pieces["water"] = _local_many(waters, origin_x, origin_z)
		pieces["stones"] = _local_many([Transform3D(stones_basis, center)], origin_x, origin_z)
	return {"pieces": pieces, "blockers": blockers}


static func _local_many(world_xforms: Array, origin_x: float, origin_z: float) -> Array:
	var local: Array[Transform3D] = []
	var shift := Vector3(origin_x, 0.0, origin_z)
	for item in world_xforms:
		var xf: Transform3D = item
		local.append(Transform3D(xf.basis, xf.origin - shift))
	return local


static func _flat_spot(params: TerrainParams, noises: Dictionary, origin_x: float, origin_z: float, spawn: Vector3) -> Dictionary:
	var best := {}
	var best_score := 1.0e20
	var margin := 6.0
	var x := origin_x + margin
	while x <= origin_x + params.chunk_size - margin:
		var z := origin_z + margin
		while z <= origin_z + params.chunk_size - margin:
			if Vector2(x, z).distance_to(Vector2(spawn.x, spawn.z)) < 12.0:
				z += 4.0
				continue
			var sample := TerrainSampler.sample_at(params, noises, x, z)
			if sample.biome != BiomeIds.HEARTHVALE:
				z += 4.0
				continue
			if not _foot_is_hearth(params, noises, x, z):
				z += 4.0
				continue
			var slope := TerrainSampler.slope_at(params, noises, x, z)
			if slope > 0.2:
				z += 4.0
				continue
			var h := float(sample.height)
			var rise := 0.0
			for offset in [Vector2(3, 0), Vector2(-3, 0), Vector2(0, 3), Vector2(0, -3)]:
				rise = maxf(rise, absf(TerrainSampler.height_at(params, noises, x + offset.x, z + offset.y) - h))
			if rise > 0.4:
				z += 4.0
				continue
			var score := slope * 4.0 + rise
			if score < best_score:
				best_score = score
				best = {"x": x, "y": h, "z": z}
			z += 4.0
		x += 4.0
	return best


static func _foot_is_hearth(params: TerrainParams, noises: Dictionary, x: float, z: float) -> bool:
	for offset in [Vector2(3.2, 0), Vector2(-3.2, 0), Vector2(0, 3.2), Vector2(0, -3.2)]:
		var sample := TerrainSampler.sample_at(params, noises, x + offset.x, z + offset.y)
		if sample.biome != BiomeIds.HEARTHVALE:
			return false
	return true


static func _parts_for(kind: String) -> Array:
	if _parts.has(kind):
		return _parts[kind]
	var path := ""
	match kind:
		"curve":
			path = BANK_CURVE
		"straight":
			path = BANK_STRAIGHT
		"water":
			path = WATER_TILE
		"stones":
			path = STONES
		_:
			_parts[kind] = []
			return []
	var packed := load(path) as PackedScene
	if packed == null:
		_parts[kind] = []
		return []
	var inst := packed.instantiate()
	var parts: Array = []
	_collect(inst, Transform3D.IDENTITY, parts)
	inst.free()
	_parts[kind] = parts
	return parts


static func _collect(node: Node, parent_xf: Transform3D, parts: Array) -> void:
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
				baked.surface_set_material(surface_index, ToonMaterial.from_source(source))
			parts.append({"mesh": baked, "local": xf})
	for child in node.get_children():
		_collect(child, xf, parts)
