class_name WorldConfig
extends Resource

## All of the knobs for Veyla's surface. Edit
## res://resources/world/world_config.tres, or select the World node and
## expand this resource in the inspector. The generator reads it once at startup.

@export var world_name: String = "Veyla"
@export var world_seed: int = 12046

@export_group("Streaming")
@export var chunk_size: float = 32.0
@export_range(5, 65, 1) var lod0_resolution: int = 33
@export_range(3, 33, 1) var lod1_resolution: int = 17
## Chebyshev radius, in chunks, kept loaded around the player. 2 is a modest phone view.
@export_range(1, 6, 1) var load_radius: int = 2
@export_range(1, 8, 1) var unload_radius: int = 4
## Chunks at this distance or farther use the coarser mesh and no props.
@export_range(1, 6, 1) var lod1_distance: int = 2
@export_range(0, 4, 1) var prop_radius: int = 1
@export_range(1, 4, 1) var max_concurrent_jobs: int = 2
@export_range(1, 4, 1) var max_applies_per_frame: int = 1
@export var skirt_depth: float = 4.0

@export_group("Terrain")
@export var sea_level: float = 7.2
@export var base_height: float = 8.0
@export var continent_amplitude: float = 12.0
@export var hill_amplitude: float = 2.8
@export var detail_amplitude: float = 0.25
@export var shallows_depth: float = 0.35
@export var beach_lift: float = 1.15
@export var coast_blend: float = 0.92
@export var inland_floor: float = 0.35
@export var floor_blend: float = 1.6

@export_group("Noise")
@export var continent_frequency: float = 0.0028
@export var hill_frequency: float = 0.02
@export var moisture_frequency: float = 0.0032
@export var wellstone_frequency: float = 0.0024
@export var detail_frequency: float = 0.047
@export_range(1, 5, 1) var continent_octaves: int = 3
@export_range(1, 4, 1) var hill_octaves: int = 2
@export_range(1, 4, 1) var moisture_octaves: int = 2
@export_range(1, 4, 1) var wellstone_octaves: int = 2
@export_range(1, 3, 1) var detail_octaves: int = 1

@export_group("Biomes")
@export var highlands_elevation: float = 0.70
@export var shallows_elevation: float = 0.40
@export var shallows_moisture: float = 0.52
@export var greying_wellstone: float = 0.30
@export var glimmer_moisture: float = 0.56
@export var glimmer_wellstone: float = 0.50
@export var coast_moisture_start: float = 0.46
@export var coast_moisture_end: float = 0.66
@export var coast_elevation_start: float = 0.18
@export var coast_elevation_end: float = 0.46

@export_group("Scatter")
@export var scatter_cell_size: float = 4.0

@export_group("Spawn")
@export var spawn_search_radius: float = 280.0
@export var spawn_search_step: float = 20.0

@export var biomes: Array[BiomeDef] = []
