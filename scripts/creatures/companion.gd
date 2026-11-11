extends Node3D

## Pyreleaf, the player's first raised Nestkin. Hearthvale and Glimmerwood.
## The mesh faces +Z. Godot's look_at aims -Z, so the visual sits on a half-turn
## pivot. Idle plays at rest and a little faster while following. There is no
## walk cycle yet. No collision, so it cannot shove the player.

const PYRELEAF_PATH := "res://assets/models/creatures/pyreleaf.glb"
const GLOW_SHADER := "res://assets/shaders/creature_glow.gdshader"
const GLOW_ADD_SHADER := "res://assets/shaders/creature_glow_add.gdshader"

const _EMISSIVE := {
	"PY_EyeHighlight": {"add": false, "base": 1.3, "amp": 0.06, "speed": 2.0},
	"PY_SeedGlow": {"add": true, "base": 1.25, "amp": 0.35, "speed": 2.6},
	"PY_Glimmer": {"add": true, "base": 1.15, "amp": 0.55, "speed": 3.6},
	"PY_GlimmerLine": {"add": true, "base": 1.05, "amp": 0.4, "speed": 3.1},
}

@export var follow_distance: float = 0.35
@export var side_distance: float = 0.85
@export var catchup: float = 4.5
@export var visual_scene: PackedScene

var _bob: float = 0.0
var _anim: AnimationPlayer
var _glow: Shader
var _glow_add: Shader


func _enter_tree() -> void:
	add_to_group("companion")


func _ready() -> void:
	_glow = load(GLOW_SHADER) as Shader
	_glow_add = load(GLOW_ADD_SHADER) as Shader
	var packed := visual_scene
	if packed == null:
		packed = load(PYRELEAF_PATH) as PackedScene
	var root := get_node_or_null("VisualRoot") as Node3D
	var placeholder := get_node_or_null("VisualRoot/Placeholder")
	if packed != null and root != null:
		var pivot := Node3D.new()
		pivot.name = "FacePivot"
		pivot.rotation.y = PI
		root.add_child(pivot)
		var visual := packed.instantiate()
		visual.name = "Pyreleaf"
		pivot.add_child(visual)
		_style(visual)
		_anim = _find_animation_player(visual)
		if _anim != null and _anim.has_animation(&"Idle"):
			var clip := _anim.get_animation(&"Idle")
			if clip != null:
				clip.loop_mode = Animation.LOOP_LINEAR
			_anim.play(&"Idle")
		_add_halo(pivot)
		_add_seed_motes(visual)
		if placeholder is Node3D:
			(placeholder as Node3D).visible = false
	elif root != null:
		ToonMaterial.apply_node(root)


func snap_to(player: Node3D) -> void:
	if player == null:
		return
	global_position = _destination(player)


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var destination := _destination(player)
	var next := global_position.lerp(destination, 1.0 - exp(-catchup * delta))
	var ground := _ground_height(next.x, next.z)
	_bob += delta
	var speed := 0.0
	if player is CharacterBody3D:
		speed = Vector2(player.velocity.x, player.velocity.z).length()
	var moving := speed > 0.35
	var hop := 0.0
	if moving:
		hop = absf(sin(_bob * 11.0)) * 0.055
	global_position = Vector3(next.x, ground + hop, next.z)
	_turn_toward(player.global_position)
	if _anim != null:
		_anim.speed_scale = 1.7 if moving else 1.0
	_swing_legs(moving)


func _destination(player: Node3D) -> Vector3:
	var forward := Vector3(0, 0, -1)
	if "facing" in player:
		forward = player.facing
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		forward = Vector3(0, 0, -1)
	forward = forward.normalized()
	var right := forward.cross(Vector3.UP).normalized()
	var pos := player.global_position - forward * follow_distance + right * side_distance
	pos.y = _ground_height(pos.x, pos.z)
	return pos


func _ground_height(x: float, z: float) -> float:
	var world := get_tree().get_first_node_in_group("world")
	if world != null and world.has_method("sample_height"):
		return world.sample_height(x, z)
	return global_position.y


func _turn_toward(target: Vector3) -> void:
	var flat := target - global_position
	flat.y = 0.0
	if flat.length_squared() < 0.02:
		return
	look_at(global_position + flat.normalized(), Vector3.UP)


func _style(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			for index in mesh_instance.mesh.get_surface_count():
				var source := mesh_instance.get_surface_override_material(index)
				if source == null:
					source = mesh_instance.mesh.surface_get_material(index)
				var material_name := ""
				if source != null:
					material_name = String(source.resource_name)
				if _EMISSIVE.has(material_name):
					mesh_instance.set_surface_override_material(index, _glow_material(source, _EMISSIVE[material_name]))
				else:
					mesh_instance.set_surface_override_material(index, ToonMaterial.from_source(source))
	for child in node.get_children():
		_style(child)


func _glow_material(source: Material, spec: Dictionary) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = _glow_add if bool(spec["add"]) else _glow
	var color := Color(1, 0.86, 0.45)
	if source is StandardMaterial3D:
		var standard := source as StandardMaterial3D
		color = standard.emission if standard.emission_enabled else standard.albedo_color
	material.set_shader_parameter("glow_color", color)
	material.set_shader_parameter("base", float(spec.base))
	material.set_shader_parameter("amp", float(spec.amp))
	material.set_shader_parameter("speed", float(spec.speed))
	return material


func _add_halo(pivot: Node3D) -> void:
	var stars := GPUParticles3D.new()
	stars.name = "GlimmerHalo"
	stars.position = Vector3(0, 0.38, 0)
	stars.amount = 8
	stars.lifetime = 1.7
	stars.preprocess = 0.8
	stars.visibility_aabb = AABB(Vector3(-1.0, -0.4, -1.0), Vector3(2.0, 1.6, 2.0))
	stars.process_material = _motes(0.32, Color(1.0, 0.9, 0.55, 0.85), 0.02, 0.1, Vector3(0, 0.06, 0))
	stars.draw_pass_1 = _spark(0.012, Color(1.0, 0.88, 0.5, 0.7))
	pivot.add_child(stars)


func _add_seed_motes(visual: Node) -> void:
	var skeleton := _find_skeleton(visual)
	var host: Node = visual
	if skeleton != null and skeleton.find_bone("seed") >= 0:
		var attachment := BoneAttachment3D.new()
		attachment.name = "SeedGlow"
		attachment.bone_name = "seed"
		skeleton.add_child(attachment)
		host = attachment
	var motes := GPUParticles3D.new()
	motes.name = "SeedMotes"
	motes.amount = 5
	motes.lifetime = 1.15
	motes.preprocess = 0.5
	motes.visibility_aabb = AABB(Vector3(-0.4, -0.2, -0.4), Vector3(0.8, 0.7, 0.8))
	motes.process_material = _motes(0.07, Color(1.0, 0.55, 0.22, 0.8), 0.04, 0.14, Vector3(0, 0.12, 0))
	motes.draw_pass_1 = _spark(0.016, Color(1.0, 0.5, 0.18, 0.75))
	host.add_child(motes)


func _motes(radius: float, color: Color, speed_min: float, speed_max: float, gravity: Vector3) -> ParticleProcessMaterial:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = radius
	process.direction = Vector3(0, 1, 0)
	process.spread = 70.0
	process.initial_velocity_min = speed_min
	process.initial_velocity_max = speed_max
	process.gravity = gravity
	process.scale_min = 0.45
	process.scale_max = 1.0
	process.color = color
	return process


func _spark(size: float, color: Color) -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2.0
	sphere.radial_segments = 6
	sphere.rings = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = color
	material.disable_receive_shadows = true
	sphere.material = material
	return sphere


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


func _swing_legs(moving: bool) -> void:
	var root := get_node_or_null("VisualRoot/Placeholder")
	if root == null or not root.visible:
		return
	var swing := sin(_bob * 8.0) * 0.45 if moving else 0.0
	for leg_name in ["LegFL", "LegBR"]:
		var leg := root.get_node_or_null(leg_name) as Node3D
		if leg != null:
			leg.rotation.x = swing
	for leg_name in ["LegFR", "LegBL"]:
		var leg := root.get_node_or_null(leg_name) as Node3D
		if leg != null:
			leg.rotation.x = -swing
