class_name TerrainSampler
extends RefCounted

## Deterministic samples of Veyla. Every height comes from world coordinates,
## so chunk edges meet and a re-run with the same seed matches.


static func create_noises(params: TerrainParams) -> Dictionary:
	return {
		"continent": _noise(params.world_seed, params.continent_frequency, params.continent_octaves),
		"hills": _noise(params.world_seed + 1013, params.hill_frequency, params.hill_octaves),
		"moisture": _noise(params.world_seed + 2029, params.moisture_frequency, params.moisture_octaves),
		"wellstone": _noise(params.world_seed + 4093, params.wellstone_frequency, params.wellstone_octaves),
		"detail": _noise(params.world_seed + 8191, params.detail_frequency, params.detail_octaves),
	}


static func chunk_coord(x: float, z: float, chunk_size: float) -> Vector2i:
	var size := chunk_size if chunk_size > 0.001 else 32.0
	return Vector2i(floori(x / size), floori(z / size))


static func hash_chunk(world_seed: int, cx: int, cz: int) -> int:
	var n := world_seed
	n = n ^ (cx * 374761393)
	n = n ^ (cz * 668265263)
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	n = absi(n)
	return 1 if n == 0 else n


static func classify(elevation: float, moisture: float, wellstone: float, params: TerrainParams) -> StringName:
	# Order is the lore: peaks, then the wet low coast, then drained midland
	# where the Wellstone network has gone quiet, then living glimmer-forest,
	# and farmland everywhere else. The Underhollows are not a surface result.
	if elevation >= params.highlands_elevation:
		return BiomeIds.CLOUDLOFT
	if elevation <= params.shallows_elevation and moisture >= params.shallows_moisture:
		return BiomeIds.SALTGLASS
	var mid := elevation > params.shallows_elevation and elevation < params.highlands_elevation
	if mid and wellstone <= params.greying_wellstone:
		return BiomeIds.GREYING
	if moisture >= params.glimmer_moisture and wellstone >= params.glimmer_wellstone:
		return BiomeIds.GLIMMERWOOD
	return BiomeIds.HEARTHVALE


static func height_at(params: TerrainParams, noises: Dictionary, x: float, z: float) -> float:
	return _compose_height(params, _climate(noises, x, z))


static func slope_at(params: TerrainParams, noises: Dictionary, x: float, z: float) -> float:
	var h := height_at(params, noises, x, z)
	var hx := height_at(params, noises, x + 1.0, z)
	var hz := height_at(params, noises, x, z + 1.0)
	return Vector2(hx - h, hz - h).length()


static func sample_at(params: TerrainParams, noises: Dictionary, x: float, z: float) -> Dictionary:
	var climate := _climate(noises, x, z)
	return _decorate(params, climate)


static func climate_at_grid(noises: Dictionary, x: float, z: float) -> Dictionary:
	return _climate(noises, x, z)


static func decorate(params: TerrainParams, climate: Dictionary) -> Dictionary:
	return _decorate(params, climate)


static func find_spawn(params: TerrainParams, noises: Dictionary) -> Vector3:
	var best := Vector2.ZERO
	var best_score := -1.0e20
	var radius := maxf(params.spawn_search_radius, params.spawn_search_step)
	var step := maxf(params.spawn_search_step, 4.0)
	var z := -radius
	while z <= radius:
		var x := -radius
		while x <= radius:
			var sample := sample_at(params, noises, x, z)
			var slope := slope_at(params, noises, x, z)
			var score := _spawn_score(params, noises, sample, slope, x, z)
			if score > best_score:
				best_score = score
				best = Vector2(x, z)
			x += step
		z += step
	var height := height_at(params, noises, best.x, best.y)
	return Vector3(best.x, height + 0.2, best.y)


static func _spawn_score(params: TerrainParams, noises: Dictionary, sample: Dictionary, slope: float, x: float, z: float) -> float:
	var score := 0.0
	match sample.biome:
		BiomeIds.HEARTHVALE:
			score += 8.0
		BiomeIds.GLIMMERWOOD:
			score += 5.0
		BiomeIds.CLOUDLOFT:
			score += 2.0
		BiomeIds.SALTGLASS:
			score += 1.5
		BiomeIds.GREYING:
			score += 1.0
		_:
			score -= 4.0
	if slope < 0.22:
		score += 3.0
	elif slope > 0.45:
		score -= 6.0
	if float(sample.height) < params.sea_level + 0.45:
		score -= 4.0
	var neighbor: StringName = sample_at(params, noises, x + 28.0, z).biome
	if neighbor != sample.biome and neighbor != BiomeIds.UNDERHOLLOWS:
		score += 3.5
	score -= Vector2(x, z).length() * 0.004
	return score


static func _decorate(params: TerrainParams, climate: Dictionary) -> Dictionary:
	var height := _compose_height(params, climate)
	var biome: StringName = classify(
		float(climate.elevation),
		float(climate.moisture),
		float(climate.wellstone),
		params
	)
	var color := _blended_ground(params, climate)
	return {
		"height": height,
		"elevation": float(climate.elevation),
		"moisture": float(climate.moisture),
		"wellstone": float(climate.wellstone),
		"biome": biome,
		"color": color,
	}


static func _blended_ground(params: TerrainParams, climate: Dictionary) -> Color:
	var elevation := float(climate.elevation)
	var moisture := float(climate.moisture)
	var wellstone := float(climate.wellstone)
	var vary := float(climate.detail)
	# A narrow band around each hard threshold. These noises are very low
	# frequency, so a wide smoothstep paints a whole meadow the neighbour's colour.
	var edge := 0.04
	var high := smoothstep(params.highlands_elevation - edge, params.highlands_elevation + edge * 0.25, elevation)
	var low := 1.0 - smoothstep(params.shallows_elevation - edge * 0.35, params.shallows_elevation + edge, elevation)
	var wet := smoothstep(params.shallows_moisture - edge, params.shallows_moisture + edge * 0.35, moisture)
	var salt := smoothstep(0.35, 0.8, clampf(low * wet, 0.0, 1.0))
	var inland := clampf(1.0 - high, 0.0, 1.0)
	var mid := smoothstep(params.shallows_elevation - edge * 0.25, params.shallows_elevation + edge, elevation)
	mid *= 1.0 - high
	var quiet := 1.0 - smoothstep(params.greying_wellstone - edge * 0.4, params.greying_wellstone + edge, wellstone)
	var grey := inland * (1.0 - salt) * mid * quiet
	var glimmer := inland * (1.0 - salt) * (1.0 - grey)
	glimmer *= smoothstep(params.glimmer_moisture - edge, params.glimmer_moisture + edge * 0.35, moisture)
	glimmer *= smoothstep(params.glimmer_wellstone - edge, params.glimmer_wellstone + edge * 0.35, wellstone)
	var hearth := maxf(0.0, 1.0 - high - salt - grey - glimmer)
	var sum := high + salt + grey + glimmer + hearth
	if sum <= 0.0001:
		sum = 1.0
		hearth = 1.0
	var color := Color(0, 0, 0, 0)
	color += _biome_tint(params, BiomeIds.CLOUDLOFT, vary) * (high / sum)
	color += _biome_tint(params, BiomeIds.SALTGLASS, vary) * (salt / sum)
	color += _biome_tint(params, BiomeIds.GREYING, vary) * (grey / sum)
	color += _biome_tint(params, BiomeIds.GLIMMERWOOD, vary) * (glimmer / sum)
	color += _biome_tint(params, BiomeIds.HEARTHVALE, vary) * (hearth / sum)
	var glimmer_info: Dictionary = params.biomes.get(BiomeIds.GLIMMERWOOD, {})
	var salt_info: Dictionary = params.biomes.get(BiomeIds.SALTGLASS, {})
	color.a = clampf(float(glimmer_info.get("glow", 0.0)) * (glimmer / sum) + float(salt_info.get("glow", 0.0)) * (salt / sum) * 0.35, 0.0, 1.0)
	return color


static func _biome_tint(params: TerrainParams, biome: StringName, vary: float) -> Color:
	var info: Dictionary = params.biomes.get(biome, {})
	var base := info.get("color", Color(0.5, 0.55, 0.4, 1.0)) as Color
	var variance := float(info.get("variance", 0.05))
	var scale := lerpf(1.0 - variance, 1.0 + variance * 0.35, vary)
	return Color(
		clampf(base.r * scale, 0.0, 1.0),
		clampf(base.g * scale, 0.0, 1.0),
		clampf(base.b * scale, 0.0, 1.0),
		1.0
	)


static func _climate(noises: Dictionary, x: float, z: float) -> Dictionary:
	return {
		"elevation": _unorm(noises.continent.get_noise_2d(x, z)),
		"hills": float(noises.hills.get_noise_2d(x, z)),
		"moisture": _unorm(noises.moisture.get_noise_2d(x, z)),
		"wellstone": _unorm(noises.wellstone.get_noise_2d(x, z)),
		"detail": _unorm(noises.detail.get_noise_2d(x, z)),
	}


static func _compose_height(params: TerrainParams, climate: Dictionary) -> float:
	var elevation := float(climate.elevation)
	var moisture := float(climate.moisture)
	var dry := params.base_height
	dry += elevation * params.continent_amplitude
	dry += float(climate.hills) * params.hill_amplitude
	dry += (float(climate.detail) - 0.5) * 2.0 * params.detail_amplitude
	# Pull wet low ground toward a shallow shelf. The blend is continuous in
	# elevation and moisture, so biome borders do not become cliffs.
	var wetness := smoothstep(params.coast_moisture_start, params.coast_moisture_end, moisture)
	var lowland := 1.0 - smoothstep(params.coast_elevation_start, params.coast_elevation_end, elevation)
	var coast := clampf(wetness * lowland, 0.0, 1.0)
	var shelf_t := clampf(elevation / maxf(params.coast_elevation_end, 0.001), 0.0, 1.0)
	var shelf := lerpf(params.sea_level - params.shallows_depth, params.sea_level + params.beach_lift, shelf_t)
	var height := lerpf(dry, shelf, coast * params.coast_blend)
	var floor_y := lerpf(params.sea_level - params.shallows_depth, params.sea_level + params.inland_floor, 1.0 - coast)
	return _smooth_max(height, floor_y, maxf(params.floor_blend, 0.25))


static func _smooth_max(a: float, b: float, k: float) -> float:
	var h := clampf(0.5 + 0.5 * (a - b) / k, 0.0, 1.0)
	return lerpf(b, a, h) + k * h * (1.0 - h)


static func _unorm(value: float) -> float:
	return clampf(value * 0.5 + 0.5, 0.0, 1.0)


static func _noise(seed_value: int, frequency: float, octaves: int) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = seed_value
	noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = maxi(octaves, 1)
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.45
	return noise
