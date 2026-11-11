class_name TerrainParams
extends RefCounted

## Plain copy of WorldConfig plus biome/prop tables.
## Safe to hand to a worker thread after [method fork]: the copy is not shared.

const SCALAR_FIELDS: Array[String] = [
	"world_seed",
	"world_name",
	"chunk_size",
	"lod0_resolution",
	"lod1_resolution",
	"load_radius",
	"unload_radius",
	"lod1_distance",
	"prop_radius",
	"max_concurrent_jobs",
	"max_applies_per_frame",
	"skirt_depth",
	"sea_level",
	"base_height",
	"continent_amplitude",
	"hill_amplitude",
	"detail_amplitude",
	"shallows_depth",
	"beach_lift",
	"coast_blend",
	"inland_floor",
	"floor_blend",
	"continent_frequency",
	"hill_frequency",
	"moisture_frequency",
	"wellstone_frequency",
	"detail_frequency",
	"continent_octaves",
	"hill_octaves",
	"moisture_octaves",
	"wellstone_octaves",
	"detail_octaves",
	"highlands_elevation",
	"shallows_elevation",
	"shallows_moisture",
	"greying_wellstone",
	"glimmer_moisture",
	"glimmer_wellstone",
	"coast_moisture_start",
	"coast_moisture_end",
	"coast_elevation_start",
	"coast_elevation_end",
	"scatter_cell_size",
	"spawn_search_radius",
	"spawn_search_step",
]

var world_seed: int = 1
var world_name: String = "Veyla"
var chunk_size: float = 32.0
var lod0_resolution: int = 33
var lod1_resolution: int = 17
var load_radius: int = 2
var unload_radius: int = 4
var lod1_distance: int = 2
var prop_radius: int = 1
var max_concurrent_jobs: int = 2
var max_applies_per_frame: int = 1
var skirt_depth: float = 4.0
var sea_level: float = 7.2
var base_height: float = 8.0
var continent_amplitude: float = 12.0
var hill_amplitude: float = 2.8
var detail_amplitude: float = 0.25
var shallows_depth: float = 0.35
var beach_lift: float = 1.15
var coast_blend: float = 0.92
var inland_floor: float = 0.35
var floor_blend: float = 1.6
var continent_frequency: float = 0.0028
var hill_frequency: float = 0.02
var moisture_frequency: float = 0.0032
var wellstone_frequency: float = 0.0024
var detail_frequency: float = 0.047
var continent_octaves: int = 3
var hill_octaves: int = 2
var moisture_octaves: int = 2
var wellstone_octaves: int = 2
var detail_octaves: int = 1
var highlands_elevation: float = 0.70
var shallows_elevation: float = 0.40
var shallows_moisture: float = 0.52
var greying_wellstone: float = 0.30
var glimmer_moisture: float = 0.56
var glimmer_wellstone: float = 0.50
var coast_moisture_start: float = 0.46
var coast_moisture_end: float = 0.66
var coast_elevation_start: float = 0.18
var coast_elevation_end: float = 0.46
var scatter_cell_size: float = 4.0
var spawn_search_radius: float = 280.0
var spawn_search_step: float = 20.0

## StringName -> {color, variance, glow, surface, name}
var biomes: Dictionary = {}
## StringName -> Array of plain prop rule dictionaries
var prop_rules: Dictionary = {}


static func from_config(cfg: WorldConfig) -> TerrainParams:
	var params := TerrainParams.new()
	if cfg == null:
		push_error("WorldConfig is null.")
		return params
	for field in SCALAR_FIELDS:
		params.set(field, cfg.get(field))
	params.biomes = {}
	params.prop_rules = {}
	for biome in cfg.biomes:
		if biome == null or String(biome.id).is_empty():
			continue
		var id: StringName = biome.id
		params.biomes[id] = {
			"color": biome.ground_color,
			"variance": biome.ground_color_variance,
			"glow": biome.ground_glow,
			"surface": biome.surface_enabled,
			"name": biome.display_name,
		}
		var rules: Array = []
		if biome.surface_enabled:
			for prop in biome.props:
				if prop == null or String(prop.id).is_empty():
					continue
				if prop.scene == null:
					push_warning("Prop '%s' has no scene; it will not scatter." % String(prop.id))
					continue
				rules.append({
					"id": String(prop.id),
					"density": prop.density,
					"min_scale": minf(prop.min_scale, prop.max_scale),
					"max_scale": maxf(prop.min_scale, prop.max_scale),
					"y_offset": prop.y_offset,
					"max_slope": tan(deg_to_rad(prop.max_slope_degrees)),
					"random_yaw": prop.random_yaw,
					"min_well": prop.min_wellstone,
					"max_well": prop.max_wellstone,
					"min_moist": prop.min_moisture,
					"max_moist": prop.max_moisture,
					"max_per_chunk": maxi(prop.max_per_chunk, 0),
					"once": prop.once_per_chunk,
				})
		params.prop_rules[id] = rules
	for id in BiomeIds.surface():
		if not params.biomes.has(id):
			push_warning("WorldConfig is missing surface biome '%s'." % String(id))
	if not params.biomes.has(BiomeIds.UNDERHOLLOWS):
		push_warning("WorldConfig is missing the Underhollows stub biome.")
	return params


func fork() -> TerrainParams:
	var copy := TerrainParams.new()
	for field in SCALAR_FIELDS:
		copy.set(field, get(field))
	copy.biomes = biomes.duplicate(true)
	copy.prop_rules = prop_rules.duplicate(true)
	return copy
