class_name VisualQuality
extends Resource

## One knob for phone cost. Medium is the default look.
## Low drops grass, motes, shoreline foam, and foliage wind.
## High spends more on ground cover and fireflies.

const PATH := "res://resources/world/visual_quality.tres"

@export_enum("low", "medium", "high") var quality: String = "medium"


static func load_default() -> VisualQuality:
	var loaded := load(PATH) as VisualQuality
	return loaded if loaded != null else VisualQuality.new()


func grass_per_chunk() -> int:
	match quality:
		"low":
			return 70
		"high":
			return 520
		_:
			return 280


func mote_amount() -> int:
	match quality:
		"low":
			return 0
		"high":
			return 40
		_:
			return 22


func shore_foam() -> bool:
	return quality != "low"


func wind_scale() -> float:
	return 0.0 if quality == "low" else 1.0


func shadow_distance() -> float:
	match quality:
		"low":
			return 26.0
		"high":
			return 60.0
		_:
			return 44.0
