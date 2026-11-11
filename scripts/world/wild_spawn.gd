class_name WildSpawn
extends RefCounted

## Deterministic groups of wild Nestkin. Cactoro likes the Saltglass and the
## dry edge of Hearthvale. Mushnub likes the Glimmerwood and damp Hearthvale.
## The companion is not one of these.

const MAX_PER_SPECIES := 3
const DRY_MOISTURE := 0.46
const DAMP_MOISTURE := 0.50
const EDGE_METRES := 14.0
const MIN_SEPARATION := 2.8


static func plan(params: TerrainParams, noises: Dictionary, origin_x: float, origin_z: float, coord: Vector2i) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = TerrainSampler.hash_chunk(params.world_seed, coord.x, coord.y) + 173
	var placed: Array = []
	_fill(placed, rng, params, noises, origin_x, origin_z, &"cactoro")
	_fill(placed, rng, params, noises, origin_x, origin_z, &"mushnub")
	return placed


static func accepts(species: StringName, params: TerrainParams, noises: Dictionary, x: float, z: float) -> bool:
	if TerrainSampler.slope_at(params, noises, x, z) > 0.42:
		return false
	var sample := TerrainSampler.sample_at(params, noises, x, z)
	var biome: StringName = sample.biome
	var moisture := float(sample.moisture)
	if species == &"cactoro":
		if biome == BiomeIds.SALTGLASS:
			return true
		if biome != BiomeIds.HEARTHVALE or moisture > DRY_MOISTURE:
			return false
		return _touches(params, noises, x, z, [BiomeIds.SALTGLASS, BiomeIds.GREYING])
	if species == &"mushnub":
		if biome == BiomeIds.GLIMMERWOOD:
			return true
		if biome != BiomeIds.HEARTHVALE or moisture < DAMP_MOISTURE:
			return false
		return true
	return false


static func _fill(placed: Array, rng: RandomNumberGenerator, params: TerrainParams, noises: Dictionary, origin_x: float, origin_z: float, species: StringName) -> void:
	var guard := 0
	var made := 0
	while made < MAX_PER_SPECIES and guard < 28:
		guard += 1
		var x := origin_x + rng.randf_range(1.5, params.chunk_size - 1.5)
		var z := origin_z + rng.randf_range(1.5, params.chunk_size - 1.5)
		if not accepts(species, params, noises, x, z):
			continue
		if not _separated(placed, x, z):
			continue
		var salt := 17 + made * 13 + (1 if species == &"mushnub" else 0)
		placed.append({
			"species": species,
			"x": x,
			"z": z,
			"seed": rng.randi() + salt,
		})
		made += 1


static func _separated(placed: Array, x: float, z: float) -> bool:
	for spot in placed:
		var dx := float(spot.x) - x
		var dz := float(spot.z) - z
		if dx * dx + dz * dz < MIN_SEPARATION * MIN_SEPARATION:
			return false
	return true


static func _touches(params: TerrainParams, noises: Dictionary, x: float, z: float, neighbours: Array) -> bool:
	for offset in [Vector2(EDGE_METRES, 0.0), Vector2(-EDGE_METRES, 0.0), Vector2(0.0, EDGE_METRES), Vector2(0.0, -EDGE_METRES)]:
		var sample := TerrainSampler.sample_at(params, noises, x + offset.x, z + offset.y)
		if neighbours.has(sample.biome):
			return true
	return false
