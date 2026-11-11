extends SceneTree

const TouchScript := preload("res://scripts/ui/touch_controls.gd")

## Headless checks for Veyla: determinism, chunk seams, biomes, slope, touch stick.
##   godot --headless --path . -s res://scripts/tests/test_world.gd


func _init() -> void:
	quit(_run())


func _run() -> int:
	# Loading the scripts registers their class_name before resources resolve.
	preload("res://scripts/world/biome_ids.gd")
	preload("res://scripts/world/prop_def.gd")
	preload("res://scripts/world/biome_def.gd")
	preload("res://scripts/world/world_config.gd")
	preload("res://scripts/world/terrain_params.gd")
	preload("res://scripts/world/terrain_sampler.gd")
	preload("res://scripts/world/chunk_mesher.gd")
	var failures: Array[String] = []
	_check_config(failures)
	var config := load("res://resources/world/world_config.tres") as WorldConfig
	if config == null:
		failures.append("WorldConfig failed to load")
		_finish(failures)
		return 1
	var params := TerrainParams.from_config(config)
	var noises := TerrainSampler.create_noises(params)
	_check_classify(params, failures)
	_check_determinism(params, noises, failures)
	_check_fork(params, noises, failures)
	_check_edges(params, noises, failures)
	_check_slope_and_coverage(params, noises, failures)
	_check_props(params, noises, failures)
	_check_stick(failures)
	_finish(failures)
	return 0 if failures.is_empty() else 1


func _check_config(failures: Array[String]) -> void:
	var config := load("res://resources/world/world_config.tres") as WorldConfig
	_expect(failures, config != null, "config loads")
	if config == null:
		return
	_expect(failures, config.world_name == "Veyla", "world is Veyla")
	_expect(failures, config.biomes.size() == 6, "six biome resources")
	_expect(failures, config.load_radius <= 3, "view distance stays modest")
	var ids: Dictionary = {}
	var under: BiomeDef = null
	for biome in config.biomes:
		ids[biome.id] = biome
		if biome.id == BiomeIds.UNDERHOLLOWS:
			under = biome
	for id in BiomeIds.surface():
		_expect(failures, ids.has(id), "surface biome present: %s" % String(id))
	_expect(failures, under != null and not under.surface_enabled, "underhollows is a non-surface stub")
	_expect(failures, under != null and under.lore_note.length() > 20, "underhollows carries a note")


func _check_classify(params: TerrainParams, failures: Array[String]) -> void:
	_expect(failures, TerrainSampler.classify(0.9, 0.2, 0.2, params) == BiomeIds.CLOUDLOFT, "high ground is cloudloft")
	_expect(failures, TerrainSampler.classify(0.2, 0.8, 0.2, params) == BiomeIds.SALTGLASS, "low wet ground is saltglass")
	_expect(failures, TerrainSampler.classify(0.55, 0.2, 0.1, params) == BiomeIds.GREYING, "quiet midland is the greying")
	_expect(failures, TerrainSampler.classify(0.55, 0.8, 0.8, params) == BiomeIds.GLIMMERWOOD, "wet living ground is glimmerwood")
	_expect(failures, TerrainSampler.classify(0.55, 0.2, 0.8, params) == BiomeIds.HEARTHVALE, "tame ground is hearthvale")
	_expect(failures, TerrainSampler.classify(0.15, 0.2, 0.1, params) == BiomeIds.HEARTHVALE, "dry hollows stay hearthvale")
	_expect(failures, TerrainSampler.classify(0.5, 0.5, 0.5, params) != BiomeIds.UNDERHOLLOWS, "classifier skips underhollows")


func _check_determinism(params: TerrainParams, noises: Dictionary, failures: Array[String]) -> void:
	var again := TerrainSampler.create_noises(params)
	var drifted := false
	for i in 12:
		var x := float(i) * 37.0 - 80.0
		var z := float(i) * -19.0 + 40.0
		var a := TerrainSampler.height_at(params, noises, x, z)
		var b := TerrainSampler.height_at(params, again, x, z)
		if absf(a - b) > 0.00001 or is_nan(a):
			drifted = true
	_expect(failures, not drifted, "same seed repeats heights")
	var other := params.fork()
	other.world_seed = params.world_seed + 19
	var other_noises := TerrainSampler.create_noises(other)
	var differed := false
	for i in 8:
		var x := 50.0 + float(i) * 23.0
		var z := -30.0 + float(i) * 17.0
		if absf(TerrainSampler.height_at(params, noises, x, z) - TerrainSampler.height_at(other, other_noises, x, z)) > 0.05:
			differed = true
	_expect(failures, differed, "a different seed changes the land")


func _check_fork(params: TerrainParams, noises: Dictionary, failures: Array[String]) -> void:
	var copy := params.fork()
	var copy_noises := TerrainSampler.create_noises(copy)
	var height_a := TerrainSampler.height_at(params, noises, 12.5, -40.0)
	var height_b := TerrainSampler.height_at(copy, copy_noises, 12.5, -40.0)
	_expect(failures, absf(height_a - height_b) < 0.00001, "forked params match")


func _check_edges(params: TerrainParams, noises: Dictionary, failures: Array[String]) -> void:
	for pair in [[Vector2i(0, 0), Vector2i(1, 0)], [Vector2i(-1, 2), Vector2i(-1, 3)], [Vector2i(-2, -4), Vector2i(-1, -4)]]:
		var left: Vector2i = pair[0]
		var right: Vector2i = pair[1]
		var a: Dictionary = ChunkMesher.build(params, noises, left, 0, false)
		var b: Dictionary = ChunkMesher.build(params, noises, right, 0, false)
		var res := params.lod0_resolution
		var seam := 0.0
		var vertical := right.y != left.y
		for i in res:
			var ia := (res - 1) * res + i if vertical else i * res + (res - 1)
			var ib := i if vertical else i * res
			var wa: Vector3 = a.vertices[ia] + Vector3(a.origin_x, 0, a.origin_z)
			var wb: Vector3 = b.vertices[ib] + Vector3(b.origin_x, 0, b.origin_z)
			seam = maxf(seam, wa.distance_to(wb))
		_expect(failures, seam < 0.0001, "chunk seam %s/%s gap=%s" % [left, right, seam])
	var fine: Dictionary = ChunkMesher.build(params, noises, Vector2i(3, -2), 0, false)
	var coarse: Dictionary = ChunkMesher.build(params, noises, Vector2i(3, -2), 1, false)
	var corner_gap := Vector3(fine.origin_x, 0, fine.origin_z).distance_to(Vector3(coarse.origin_x, 0, coarse.origin_z))
	var fine_corner: Vector3 = fine.vertices[0]
	var coarse_corner: Vector3 = coarse.vertices[0]
	_expect(failures, corner_gap == 0.0 and fine_corner.distance_to(coarse_corner) < 0.0001, "lod corners share a height")
	var res0 := params.lod0_resolution
	_expect(failures, fine.vertices.size() == res0 * res0 + 4 * res0, "skirts add a dropped edge")
	_expect(failures, _upward(fine), "terrain winding faces up")


func _check_slope_and_coverage(params: TerrainParams, noises: Dictionary, failures: Array[String]) -> void:
	var counts := {}
	for id in BiomeIds.surface():
		counts[id] = 0
	counts[BiomeIds.UNDERHOLLOWS] = 0
	var max_slope := 0.0
	var worst := Vector2.ZERO
	var step := 40.0
	var x := -1600.0
	while x <= 1600.0:
		var z := -1600.0
		while z <= 1600.0:
			var sample: Dictionary = TerrainSampler.sample_at(params, noises, x, z)
			var biome: StringName = sample.biome
			counts[biome] = int(counts.get(biome, 0)) + 1
			if not is_finite(float(sample.height)):
				failures.append("non-finite height at %s,%s" % [x, z])
				return
			z += step
		x += step
	var sx := -240.0
	while sx <= 240.0:
		var sz := -240.0
		while sz <= 240.0:
			var slope := TerrainSampler.slope_at(params, noises, sx, sz)
			if slope > max_slope:
				max_slope = slope
				worst = Vector2(sx, sz)
			sz += 6.0
		sx += 6.0
	print("Biome histogram: ", counts)
	print("Max slope (rise/run) ", max_slope, " at ", worst)
	for id in BiomeIds.surface():
		_expect(failures, int(counts.get(id, 0)) > 0, "world contains %s" % String(id))
	_expect(failures, int(counts.get(BiomeIds.UNDERHOLLOWS, 0)) == 0, "underhollows are not on the surface")
	# ~35 degrees. Rolling hills should stay under this.
	_expect(failures, max_slope < 0.75, "terrain stays walkable (max slope %s)" % max_slope)
	var spawn := TerrainSampler.find_spawn(params, noises)
	var spawn_sample: Dictionary = TerrainSampler.sample_at(params, noises, spawn.x, spawn.z)
	_expect(failures, is_finite(spawn.y), "spawn height is finite")
	_expect(failures, spawn_sample.biome != BiomeIds.UNDERHOLLOWS, "spawn is on the surface")
	_expect(failures, float(spawn_sample.height) > params.sea_level - params.shallows_depth - 0.2, "spawn is not under the sea floor")


func _check_props(params: TerrainParams, noises: Dictionary, failures: Array[String]) -> void:
	var coord := Vector2i(2, -3)
	var first: Dictionary = ChunkMesher.build(params, noises, coord, 0, true)
	var second: Dictionary = ChunkMesher.build(params, noises, coord, 0, true)
	_expect(failures, first.props.keys().size() == second.props.keys().size(), "prop sets match")
	var same := true
	for key in first.props.keys():
		var a: Array = first.props[key]
		var b: Array = second.props.get(key, [])
		if a.size() != b.size():
			same = false
			break
		if a.size() > 0 and (a[0] as Transform3D).origin.distance_to((b[0] as Transform3D).origin) > 0.0001:
			same = false
	_expect(failures, same, "scatter is deterministic")
	for key in first.props.keys():
		var placed: Array = first.props[key]
		if String(key) == "wellstone" or String(key) == "dull_stone":
			_expect(failures, placed.size() <= 1, "%s stays a landmark" % String(key))


func _check_stick(failures: Array[String]) -> void:
	var up: Vector2 = TouchScript.stick_vector(Vector2(0, 100), Vector2(0, 50), 50.0, 0.12)
	var right: Vector2 = TouchScript.stick_vector(Vector2.ZERO, Vector2(40, 0), 40.0, 0.12)
	var tiny: Vector2 = TouchScript.stick_vector(Vector2.ZERO, Vector2(2, -1), 80.0, 0.12)
	_expect(failures, up.y > 0.9 and absf(up.x) < 0.01, "stick up is forward")
	_expect(failures, right.x > 0.9 and absf(right.y) < 0.01, "stick right is right")
	_expect(failures, tiny == Vector2.ZERO, "stick deadzone holds")


func _upward(data: Dictionary) -> bool:
	var verts: PackedVector3Array = data.vertices
	var indices: PackedInt32Array = data.indices
	if indices.size() < 3:
		return false
	var a: Vector3 = verts[indices[0]]
	var b: Vector3 = verts[indices[1]]
	var c: Vector3 = verts[indices[2]]
	return (b - a).cross(c - a).y > 0.0


func _expect(failures: Array[String], ok: bool, label: String) -> void:
	if ok:
		print("PASS ", label)
	else:
		push_error("FAIL " + label)
		failures.append(label)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("ALL TESTS PASSED")
	else:
		print("FAILURES ", failures.size())
		for failure in failures:
			print(" - ", failure)
