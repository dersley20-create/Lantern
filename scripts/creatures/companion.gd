class_name Companion
extends Node3D

## The raised companion. Fox is the Hearthvale default. A Glimmerwood nest
## uses the cat, and a Cloudloft nest uses the owl. Cactoro and Mushnub stay
## wild. Pyreleaf is unused. The GLBs are already 0.6–0.7 m, so scale stays 1.
## They face +Z. look_at aims -Z, so the visual sits on a half-turn pivot.

const MODELS := {
	"fox": "res://assets/models/creatures/fox_hearthvale.glb",
	"cat": "res://assets/models/creatures/cat_glimmerwood.glb",
	"owl": "res://assets/models/creatures/owl_cloudloft.glb",
}
const GLOW_NAMES := ["NK_Glimmer", "NK_Glowcap", "NK_Crystal", "NK_Flower"]

@export_enum("fox", "cat", "owl") var species: String = "fox"
## When true, the look follows the biome under the player at the moment they nest.
@export var nest_from_biome: bool = true

@export var follow_distance: float = 0.95
@export var side_distance: float = 0.72
@export var catchup: float = 4.4
## A posed companion stands where it was placed. The close lineup uses this.
@export var posed: bool = false

var _tree: AnimationTree
var _playback: AnimationNodeStateMachinePlayback
var _clips := {}
var _state := ""
var _lock := 0.0
var _idle_time := 0.0
var _visual: Node3D
var _mounted: bool = false
var _rng := RandomNumberGenerator.new()


func _enter_tree() -> void:
	if not posed:
		add_to_group("companion")


func _ready() -> void:
	if _mounted:
		return
	_rng.randomize()
	var forced := OS.get_environment("LANTERN_COMPANION")
	if MODELS.has(forced):
		species = forced
		nest_from_biome = false
	_mount()


func snap_to(body: Node3D) -> void:
	if body == null:
		return
	if nest_from_biome:
		_apply_biome(body.global_position)
	global_position = _destination(body)
	print("Lantern companion=%s" % species)


func _process(delta: float) -> void:
	if posed or not is_inside_tree():
		return
	var body := get_tree().get_first_node_in_group("player") as Node3D
	if body == null:
		return
	var destination := _destination(body)
	var next := global_position.lerp(destination, 1.0 - exp(-catchup * delta))
	var ground := _ground_height(next.x, next.z)
	var speed := 0.0
	if body is CharacterBody3D:
		speed = Vector2(body.velocity.x, body.velocity.z).length()
	var gap := absf(ground - global_position.y)
	global_position = Vector3(next.x, ground, next.z)
	var moving := speed > 0.3 or global_position.distance_to(destination) > 0.45
	if moving:
		var travel := destination - global_position
		travel.y = 0.0
		if travel.length_squared() > 0.02:
			_turn_toward(global_position + travel.normalized())
	else:
		_turn_toward(body.global_position)
	_drive(delta, moving, speed, gap)


func _apply_biome(at: Vector3) -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world == null or not world.has_method("sample_biome"):
		return
	var biome: StringName = world.sample_biome(at.x, at.z)
	var want := "fox"
	if biome == BiomeIds.GLIMMERWOOD:
		want = "cat"
	elif biome == BiomeIds.CLOUDLOFT:
		want = "owl"
	if want == species and _visual != null:
		return
	species = want
	_mount()


func _mount() -> void:
	var root := get_node_or_null("VisualRoot") as Node3D
	if root == null:
		return
	if _tree != null:
		_tree.queue_free()
		_tree = null
		_playback = null
	if _visual != null:
		_visual.queue_free()
		_visual = null
	var packed := load(_model_path()) as PackedScene
	if packed == null:
		return
	var placeholder := root.get_node_or_null("Placeholder")
	if placeholder is Node3D:
		(placeholder as Node3D).visible = false
	var pivot := Node3D.new()
	pivot.name = "FacePivot"
	pivot.rotation.y = PI
	root.add_child(pivot)
	var visual := packed.instantiate()
	visual.name = species.capitalize()
	pivot.add_child(visual)
	_visual = pivot
	_style(visual)
	var player := _find_animation_player(visual)
	_bind_tree(player)
	_mounted = true


func _drive(delta: float, moving: bool, speed: float, gap: float) -> void:
	if _playback == null:
		return
	_lock = maxf(0.0, _lock - delta)
	if gap > 0.4 and _state != "Jump":
		_go("Jump", 0.45)
		return
	if _lock > 0.0:
		return
	if moving:
		_idle_time = 0.0
		if speed > 3.1 and _clips.get("Fast", StringName()) != StringName():
			_set_scale("Fast", clampf(speed / 4.6, 0.75, 1.35))
			_go("Fast")
		else:
			_set_scale("Walk", clampf(speed / 2.2, 0.7, 1.45))
			_go("Walk")
		return
	_idle_time += delta
	if _state == "Idle" and _idle_time > _rng.randf_range(2.4, 4.2):
		_idle_time = 0.0
		var fidget := "Call" if _rng.randf() < 0.55 else "IdleAlt"
		_go(fidget, 0.9)
		return
	_go("Idle")


func _go(state: String, lock_for: float = 0.0) -> void:
	if _clips.get(state, StringName()) == StringName():
		state = "Idle"
	if state == _state:
		return
	_state = state
	_lock = lock_for
	_playback.travel(state)


func _set_scale(state: String, ratio: float) -> void:
	if _tree == null:
		return
	_tree.set("parameters/%s/timescale/scale" % state, ratio)


func _destination(body: Node3D) -> Vector3:
	var forward := Vector3(0, 0, -1)
	if "facing" in body:
		forward = body.facing
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		forward = Vector3(0, 0, -1)
	forward = forward.normalized()
	var right := forward.cross(Vector3.UP).normalized()
	var pos := body.global_position - forward * follow_distance + right * side_distance
	pos.y = _ground_height(pos.x, pos.z)
	return pos


func _ground_height(x: float, z: float) -> float:
	var world := get_tree().get_first_node_in_group("world")
	if world != null and world.has_method("sample_height"):
		return world.sample_height(x, z)
	return global_position.y


func _turn_toward(target: Vector3) -> void:
	if not is_inside_tree():
		return
	var flat := target - global_position
	flat.y = 0.0
	if flat.length_squared() < 0.02:
		return
	look_at(global_position + flat.normalized(), Vector3.UP)


func _model_path() -> String:
	if MODELS.has(species):
		return String(MODELS[species])
	species = "fox"
	return String(MODELS["fox"])


func _bind_tree(player: AnimationPlayer) -> void:
	if player == null:
		return
	_clips = {}
	_clips["Idle"] = _find_clip(player, "idle")
	_clips["Walk"] = _find_clip(player, "walk")
	_clips["Fast"] = _find_clip(player, "fly") if species == "owl" else _find_clip(player, "run")
	_clips["Jump"] = _find_clip(player, "jump")
	_clips["Call"] = _find_clip(player, "call")
	_clips["IdleAlt"] = _find_clip(player, "idle_alt")
	for key in _clips.keys():
		var clip_name: StringName = _clips[key]
		if clip_name == StringName():
			continue
		var clip := player.get_animation(clip_name)
		if clip == null:
			continue
		var once: bool = key == "Jump" or key == "Call"
		clip.loop_mode = Animation.LOOP_NONE if once else Animation.LOOP_LINEAR
	_tree = AnimationTree.new()
	_tree.name = "CompanionTree"
	add_child(_tree)
	_tree.anim_player = _tree.get_path_to(player)
	_tree.tree_root = _machine()
	_tree.active = true
	_playback = _tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	_state = "Idle"


func _machine() -> AnimationNodeStateMachine:
	var machine := AnimationNodeStateMachine.new()
	for state in ["Idle", "Walk", "Fast", "Jump", "Call", "IdleAlt"]:
		if _clips.get(state, StringName()) == StringName():
			continue
		_add_state(machine, state, state == "Walk" or state == "Fast")
	_link(machine, "Start", "Idle", 0.0, false)
	_link(machine, "Idle", "Walk", 0.15, false)
	_link(machine, "Walk", "Idle", 0.18, false)
	_link(machine, "Idle", "Fast", 0.12, false)
	_link(machine, "Walk", "Fast", 0.12, false)
	_link(machine, "Fast", "Walk", 0.12, false)
	_link(machine, "Fast", "Idle", 0.16, false)
	for source in ["Idle", "Walk", "Fast"]:
		_link(machine, source, "Jump", 0.05, false)
	_link(machine, "Jump", "Idle", 0.1, true)
	_link(machine, "Idle", "Call", 0.1, false)
	_link(machine, "Idle", "IdleAlt", 0.12, false)
	_link(machine, "Call", "Idle", 0.12, true)
	_link(machine, "IdleAlt", "Idle", 0.15, false)
	_link(machine, "Call", "Walk", 0.1, false)
	_link(machine, "IdleAlt", "Walk", 0.1, false)
	return machine


func _add_state(machine: AnimationNodeStateMachine, state: String, scaled: bool) -> void:
	var clip_name: StringName = _clips.get(state, StringName())
	var anim := AnimationNodeAnimation.new()
	if clip_name != StringName():
		anim.animation = clip_name
	if not scaled:
		machine.add_node(state, anim)
		return
	var blend := AnimationNodeBlendTree.new()
	var scale := AnimationNodeTimeScale.new()
	blend.add_node("anim", anim)
	blend.add_node("timescale", scale)
	blend.connect_node("timescale", 0, "anim")
	blend.connect_node("output", 0, "timescale")
	machine.add_node(state, blend)


func _link(machine: AnimationNodeStateMachine, from: String, to: String, fade: float, auto_end: bool) -> void:
	if from != "Start" and _clips.get(from, StringName()) == StringName():
		return
	if _clips.get(to, StringName()) == StringName():
		return
	var transition := AnimationNodeStateMachineTransition.new()
	transition.xfade_time = fade
	if auto_end:
		transition.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
		transition.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	else:
		transition.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
	machine.add_transition(from, to, transition)


func _find_clip(player: AnimationPlayer, suffix: String) -> StringName:
	for name in player.get_animation_list():
		if String(name) == suffix:
			return name
	return StringName()


func _style(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			for index in mesh_instance.mesh.get_surface_count():
				var source := mesh_instance.get_surface_override_material(index)
				if source == null:
					source = mesh_instance.mesh.surface_get_material(index)
				var mat := ToonMaterial.from_source(source)
				var material_name := String(source.resource_name) if source != null else ""
				if GLOW_NAMES.has(material_name):
					var energy := float(mat.get_shader_parameter("emission_energy"))
					mat.set_shader_parameter("emission_energy", maxf(energy, 1.2))
				mesh_instance.set_surface_override_material(index, mat)
	for child in node.get_children():
		_style(child)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


static func make_portrait(which: String) -> Companion:
	var host := Companion.new()
	host.species = which
	host.nest_from_biome = false
	host.posed = true
	host.name = "Portrait%s" % which.capitalize()
	var root := Node3D.new()
	root.name = "VisualRoot"
	host.add_child(root)
	return host
