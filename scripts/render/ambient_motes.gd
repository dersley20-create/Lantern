extends GPUParticles3D

## A single halo that follows the player. Colour follows the biome:
## warm fireflies in Hearthvale, cyan glimmer in the wood, almost none in the Greying.

var _quality: VisualQuality
var _base_amount: int = 16


func _ready() -> void:
	_quality = VisualQuality.load_default()
	_base_amount = _quality.mote_amount() if _quality != null else 16
	amount = _base_amount
	lifetime = 2.4
	preprocess = 1.0
	visibility_aabb = AABB(Vector3(-8, -2, -8), Vector3(16, 6, 16))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(7.0, 1.2, 7.0)
	process.direction = Vector3(0, 1, 0)
	process.spread = 80.0
	process.initial_velocity_min = 0.05
	process.initial_velocity_max = 0.22
	process.gravity = Vector3(0, 0.03, 0)
	process.scale_min = 0.4
	process.scale_max = 1.0
	process.color = Color(1.0, 0.86, 0.45, 0.75)
	process_material = process
	var spark := SphereMesh.new()
	spark.radius = 0.09
	spark.height = 0.18
	spark.radial_segments = 6
	spark.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = Color(1.0, 0.9, 0.55, 0.8)
	material.disable_receive_shadows = true
	spark.material = material
	draw_pass_1 = spark
	emitting = _base_amount > 0


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	global_position = player.global_position + Vector3(0, 1.4, 0)
	var world := get_tree().get_first_node_in_group("world")
	if world == null or not world.has_method("sample_biome"):
		return
	var biome: StringName = world.sample_biome(player.global_position.x, player.global_position.z)
	var color := Color(1.0, 0.86, 0.42, 0.8)
	var scale := 1.0
	match biome:
		BiomeIds.GLIMMERWOOD:
			color = Color(0.55, 0.95, 0.9, 0.9)
			scale = 1.4
		BiomeIds.SALTGLASS:
			color = Color(0.7, 0.9, 0.95, 0.55)
			scale = 0.45
		BiomeIds.CLOUDLOFT:
			color = Color(0.8, 0.9, 1.0, 0.5)
			scale = 0.4
		BiomeIds.GREYING:
			color = Color(0.85, 0.7, 0.4, 0.35)
			scale = 0.2
		_:
			color = Color(1.0, 0.84, 0.4, 0.75)
			scale = 0.85
	var count := int(round(_base_amount * scale))
	if amount != count:
		amount = count
		emitting = count > 0
	var process := process_material as ParticleProcessMaterial
	if process != null:
		process.color = color
	if draw_pass_1 is SphereMesh and (draw_pass_1 as SphereMesh).material is StandardMaterial3D:
		((draw_pass_1 as SphereMesh).material as StandardMaterial3D).albedo_color = color
