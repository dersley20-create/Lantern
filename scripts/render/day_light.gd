extends Node

## Golden morning by default. A full day is optional and stays soft at night
## so the world never drops to black. Phones can leave the cycle off.

@export var hour: float = 9.2
@export var cycle: bool = false
@export var day_length_seconds: float = 720.0

var _sun: DirectionalLight3D
var _fill: DirectionalLight3D
var _environment: Environment
var _sky: ProceduralSkyMaterial
var _quality: VisualQuality


func _ready() -> void:
	add_to_group("day_light")
	_quality = VisualQuality.load_default()
	_sun = get_node_or_null("../Sun") as DirectionalLight3D
	_fill = get_node_or_null("../Fill") as DirectionalLight3D
	var world_env := get_node_or_null("../WorldEnvironment") as WorldEnvironment
	if world_env != null:
		_environment = world_env.environment
		if _environment != null and _environment.sky != null:
			_sky = _environment.sky.sky_material as ProceduralSkyMaterial
	_apply()


func _process(delta: float) -> void:
	if not cycle:
		return
	hour = fposmod(hour + delta / maxf(day_length_seconds, 1.0) * 24.0, 24.0)
	_apply()


func _apply() -> void:
	var day := smoothstep(5.2, 7.4, hour) * (1.0 - smoothstep(17.6, 20.2, hour))
	var golden := _bell(hour, 8.2, 1.6) + _bell(hour, 17.4, 1.4)
	var night := 1.0 - day
	if _sun != null:
		var elev := sin(clampf((hour - 6.0) / 12.0, 0.0, 1.0) * PI)
		var pitch := lerpf(-12.0, -58.0, elev)
		var yaw := lerpf(-55.0, 70.0, clampf((hour - 6.0) / 12.0, 0.0, 1.0))
		if night > 0.85:
			pitch = -28.0
			yaw = 20.0
		_sun.rotation_degrees = Vector3(pitch, yaw, 0.0)
		var warmth := clampf(golden, 0.0, 1.0) * 0.32
		var sun_color := Color(1.0, 0.96, 0.9).lerp(Color(1.0, 0.84, 0.62), warmth)
		sun_color = sun_color.lerp(Color(0.62, 0.72, 0.95), night)
		_sun.light_color = sun_color
		_sun.light_energy = lerpf(0.22, 1.02, day)
		_sun.directional_shadow_max_distance = _quality.shadow_distance() if _quality != null else 44.0
	if _fill != null:
		_fill.light_color = Color(0.62, 0.74, 0.95).lerp(Color(0.45, 0.52, 0.78), night)
		_fill.light_energy = lerpf(0.18, 0.26, day)
	if _sky != null:
		_sky.sky_top_color = Color(0.42, 0.68, 0.95).lerp(Color(0.1, 0.13, 0.24), night)
		_sky.sky_horizon_color = Color(0.78, 0.88, 0.98).lerp(Color(0.98, 0.78, 0.58), clampf(golden, 0.0, 1.0) * 0.4 * day)
		_sky.sky_horizon_color = _sky.sky_horizon_color.lerp(Color(0.28, 0.32, 0.48), night)
		_sky.ground_horizon_color = Color(0.62, 0.7, 0.58).lerp(Color(0.2, 0.22, 0.28), night)
		_sky.ground_bottom_color = Color(0.34, 0.4, 0.32).lerp(Color(0.08, 0.09, 0.12), night)
	if _environment != null:
		var fog := Color(0.74, 0.84, 0.94).lerp(Color(0.95, 0.82, 0.66), clampf(golden, 0.0, 1.0) * 0.22)
		fog = fog.lerp(Color(0.32, 0.36, 0.5), night)
		_environment.fog_light_color = fog
		_environment.fog_density = lerpf(0.0016, 0.0032, night)
		_environment.fog_aerial_perspective = 0.2
		_environment.fog_sun_scatter = lerpf(0.08, 0.2, clampf(golden, 0.0, 1.0))
		_environment.ambient_light_energy = lerpf(0.28, 0.48, day)
		_environment.adjustment_enabled = true
		_environment.adjustment_brightness = 1.0
		_environment.adjustment_contrast = 1.08
		_environment.adjustment_saturation = 1.2
		_environment.tonemap_exposure = 1.02


func _bell(value: float, center: float, width: float) -> float:
	var d := (value - center) / width
	return exp(-d * d)
