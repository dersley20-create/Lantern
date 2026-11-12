extends Node3D

## Windows and lamps burn warmer toward dusk. DayLight.hour drives the scale.
## With the day cycle off, the morning value is applied once.

var _glows: Array[ShaderMaterial] = []
var _lamps: Array[OmniLight3D] = []
var _applied: float = -1.0


func remember_glow(material: ShaderMaterial) -> void:
	_glows.append(material)


func remember_lamp(lamp: OmniLight3D) -> void:
	_lamps.append(lamp)


func _ready() -> void:
	_apply(_scale())


func _process(_delta: float) -> void:
	var day := get_tree().get_first_node_in_group("day_light")
	if day == null or not bool(day.get("cycle")):
		return
	_apply(_scale())


func _apply(scale: float) -> void:
	if absf(scale - _applied) < 0.03:
		return
	_applied = scale
	for material in _glows:
		if not is_instance_valid(material):
			continue
		var base := float(material.get_meta("glow_base", 1.6))
		material.set_shader_parameter("emission_energy", base * scale)
	for lamp in _lamps:
		if is_instance_valid(lamp):
			lamp.light_energy = 0.22 * scale


func _scale() -> float:
	var hour := 9.2
	var day := get_tree().get_first_node_in_group("day_light")
	if day != null:
		hour = float(day.get("hour"))
	var day_amount := smoothstep(5.2, 7.4, hour) * (1.0 - smoothstep(17.6, 20.2, hour))
	var dusk := _bell(hour, 18.6, 1.7) + _bell(hour, 6.2, 1.1)
	return lerpf(1.65, 1.0, day_amount) + dusk * 0.35


func _bell(value: float, center: float, width: float) -> float:
	var d := (value - center) / width
	return exp(-d * d)
