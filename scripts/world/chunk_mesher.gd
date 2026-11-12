class_name ChunkMesher
extends RefCounted

## Builds mesh arrays for one chunk. Pure data: no scene-tree calls, so a
## worker thread can run it. Collision faces are the top surface only.


static func build(params: TerrainParams, noises: Dictionary, coord: Vector2i, lod: int, with_props: bool) -> Dictionary:
	var res := params.lod0_resolution if lod <= 0 else params.lod1_resolution
	res = maxi(res, 2)
	var chunk_size := params.chunk_size
	var origin_x := float(coord.x) * chunk_size
	var origin_z := float(coord.y) * chunk_size
	var step := chunk_size / float(res - 1)
	var grid_n := res + 2
	var cell_count := grid_n * grid_n
	var elevation := PackedFloat32Array()
	var hills := PackedFloat32Array()
	var moisture := PackedFloat32Array()
	var wellstone := PackedFloat32Array()
	var detail := PackedFloat32Array()
	var heights := PackedFloat32Array()
	elevation.resize(cell_count)
	hills.resize(cell_count)
	moisture.resize(cell_count)
	wellstone.resize(cell_count)
	detail.resize(cell_count)
	heights.resize(cell_count)
	for gz in grid_n:
		for gx in grid_n:
			var wx := origin_x + float(gx - 1) * step
			var wz := origin_z + float(gz - 1) * step
			var climate := TerrainSampler.climate_at_grid(noises, wx, wz)
			var index := gz * grid_n + gx
			elevation[index] = float(climate.elevation)
			hills[index] = float(climate.hills)
			moisture[index] = float(climate.moisture)
			wellstone[index] = float(climate.wellstone)
			detail[index] = float(climate.detail)
			heights[index] = VillageLayout.blend(wx, wz, TerrainSampler._compose_height(params, climate))

	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	verts.resize(res * res)
	normals.resize(res * res)
	colors.resize(res * res)
	for z in res:
		for x in res:
			var gx := x + 1
			var gz := z + 1
			var index := gz * grid_n + gx
			var vertex_index := z * res + x
			var h: float = heights[index]
			verts[vertex_index] = Vector3(float(x) * step, h, float(z) * step)
			var hl: float = heights[gz * grid_n + (gx - 1)]
			var hr: float = heights[gz * grid_n + (gx + 1)]
			var hd: float = heights[(gz - 1) * grid_n + gx]
			var hu: float = heights[(gz + 1) * grid_n + gx]
			var normal := Vector3(hl - hr, 2.0 * step, hd - hu)
			normals[vertex_index] = normal.normalized() if normal.length_squared() > 0.000001 else Vector3.UP
			var decorated := TerrainSampler.decorate(params, {
				"elevation": elevation[index],
				"hills": hills[index],
				"moisture": moisture[index],
				"wellstone": wellstone[index],
				"detail": detail[index],
			})
			colors[vertex_index] = decorated.color

	var quads := (res - 1) * (res - 1)
	var indices := PackedInt32Array()
	var faces := PackedVector3Array()
	indices.resize(quads * 6)
	faces.resize(quads * 6)
	var cursor := 0
	for z in res - 1:
		for x in res - 1:
			var i := z * res + x
			var a := i
			var b := i + res
			var c := i + 1
			var d := i + res + 1
			# Winding is CCW when viewed from above (Godot front face).
			var tris := [a, b, c, c, b, d]
			for vertex_index in tris:
				indices[cursor] = vertex_index
				faces[cursor] = verts[vertex_index]
				cursor += 1

	var skirted := _with_skirts(verts, normals, colors, indices, res, params.skirt_depth)
	var props := {}
	if with_props:
		props = _scatter(params, noises, origin_x, origin_z, coord)

	return {
		"coord": coord,
		"lod": lod,
		"with_props": with_props,
		"origin_x": origin_x,
		"origin_z": origin_z,
		"vertices": skirted.vertices,
		"normals": skirted.normals,
		"colors": skirted.colors,
		"indices": skirted.indices,
		"faces": faces,
		"props": props,
	}


static func _with_skirts(
	verts: PackedVector3Array,
	normals: PackedVector3Array,
	colors: PackedColorArray,
	indices: PackedInt32Array,
	res: int,
	depth: float
) -> Dictionary:
	if depth <= 0.0:
		return {"vertices": verts, "normals": normals, "colors": colors, "indices": indices}
	var chains: Array = [
		[_chain_row(res, 0), Vector3(0, -0.15, -1).normalized()],
		[_chain_row(res, res - 1), Vector3(0, -0.15, 1).normalized()],
		[_chain_col(res, 0), Vector3(-1, -0.15, 0).normalized()],
		[_chain_col(res, res - 1), Vector3(1, -0.15, 0).normalized()],
	]
	for item in chains:
		var chain: Array = item[0]
		var outward: Vector3 = item[1]
		var base := verts.size()
		for index in chain:
			var vertex: Vector3 = verts[index]
			verts.append(Vector3(vertex.x, vertex.y - depth, vertex.z))
			normals.append(outward)
			colors.append(colors[index])
		for i in chain.size() - 1:
			var top_a: int = chain[i]
			var top_b: int = chain[i + 1]
			var low_a := base + i
			var low_b := base + i + 1
			indices.append(top_a)
			indices.append(low_a)
			indices.append(top_b)
			indices.append(top_b)
			indices.append(low_a)
			indices.append(low_b)
	return {"vertices": verts, "normals": normals, "colors": colors, "indices": indices}


static func _chain_row(res: int, z: int) -> Array:
	var chain: Array[int] = []
	chain.resize(res)
	for x in res:
		chain[x] = z * res + x
	return chain


static func _chain_col(res: int, x: int) -> Array:
	var chain: Array[int] = []
	chain.resize(res)
	for z in res:
		chain[z] = z * res + x
	return chain


static func _scatter(params: TerrainParams, noises: Dictionary, origin_x: float, origin_z: float, coord: Vector2i) -> Dictionary:
	var props := {}
	var placed := {}
	var rng := RandomNumberGenerator.new()
	rng.seed = TerrainSampler.hash_chunk(params.world_seed, coord.x, coord.y)
	var chunk_size := params.chunk_size
	# One landmark roll per chunk, independent of how many cells we walk.
	var landmark_x := origin_x + rng.randf_range(2.0, chunk_size - 2.0)
	var landmark_z := origin_z + rng.randf_range(2.0, chunk_size - 2.0)
	var landmark := TerrainSampler.sample_at(params, noises, landmark_x, landmark_z)
	var landmark_slope := TerrainSampler.slope_at(params, noises, landmark_x, landmark_z)
	for rule in params.prop_rules.get(landmark.biome, []):
		if not bool(rule.once):
			continue
		if not _rule_allows(rule, landmark, landmark_slope):
			continue
		if rng.randf() > float(rule.density):
			continue
		_place(props, placed, rule, rng, origin_x, origin_z, landmark_x, landmark_z, float(landmark.height))
	var cell := maxf(params.scatter_cell_size, 1.0)
	var cells := int(floor(chunk_size / cell))
	for iz in cells:
		for ix in cells:
			var world_x := origin_x + (float(ix) + 0.5) * cell + rng.randf_range(-cell * 0.3, cell * 0.3)
			var world_z := origin_z + (float(iz) + 0.5) * cell + rng.randf_range(-cell * 0.3, cell * 0.3)
			world_x = clampf(world_x, origin_x + 0.4, origin_x + chunk_size - 0.4)
			world_z = clampf(world_z, origin_z + 0.4, origin_z + chunk_size - 0.4)
			var sample := TerrainSampler.sample_at(params, noises, world_x, world_z)
			var slope := TerrainSampler.slope_at(params, noises, world_x, world_z)
			for rule in params.prop_rules.get(sample.biome, []):
				if bool(rule.once):
					continue
				if int(placed.get(rule.id, 0)) >= int(rule.max_per_chunk):
					continue
				if not _rule_allows(rule, sample, slope):
					continue
				if rng.randf() > float(rule.density):
					continue
				_place(props, placed, rule, rng, origin_x, origin_z, world_x, world_z, float(sample.height))
	_span_rope_bridge(props)
	return props


static func _span_rope_bridge(props: Dictionary) -> void:
	# The kit segment is 3 m with a post on -X. A short run reads as a bridge.
	var id := "cloudloft_rope_bridge"
	if not props.has(id):
		return
	var spans: Array = props[id]
	var grown: Array = []
	for item in spans:
		var first: Transform3D = item
		grown.append(first)
		var dir := Vector3(first.basis.x.x, 0.0, first.basis.x.z)
		if dir.length_squared() < 0.0001:
			dir = Vector3.RIGHT
		dir = dir.normalized()
		grown.append(Transform3D(first.basis, first.origin + dir * 3.0))
		grown.append(Transform3D(first.basis, first.origin + dir * 6.0))
	props[id] = grown


static func _rule_allows(rule: Dictionary, sample: Dictionary, slope: float) -> bool:
	if float(sample.wellstone) < float(rule.min_well) or float(sample.wellstone) > float(rule.max_well):
		return false
	if float(sample.moisture) < float(rule.min_moist) or float(sample.moisture) > float(rule.max_moist):
		return false
	if slope > float(rule.max_slope):
		return false
	return true


static func _place(props: Dictionary, placed: Dictionary, rule: Dictionary, rng: RandomNumberGenerator, origin_x: float, origin_z: float, world_x: float, world_z: float, height: float) -> void:
	var yaw := rng.randf() * TAU if bool(rule.random_yaw) else 0.0
	var scl := rng.randf_range(float(rule.min_scale), float(rule.max_scale))
	var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl)
	var local := Vector3(world_x - origin_x, height + float(rule.y_offset), world_z - origin_z)
	var id: String = rule.id
	if not props.has(id):
		props[id] = []
	(props[id] as Array).append(Transform3D(basis, local))
	placed[id] = int(placed.get(id, 0)) + 1
