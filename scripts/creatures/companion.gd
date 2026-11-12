extends Node3D

## The player's companion. Mushnub by default; set species to cactoro to swap.
## Pyreleaf stays in the repo and is not used here. The mesh is authored near
## 3.5 m, so the visual is instanced at 0.33. An AnimationTree drives Idle,
## Walk (sped with movement, since there is no run clip), Jump, and Yes/Dance.
## NK_Cap and NK_Band stay emissive. No collision, so it cannot shove the player.

const SCALE := 0.33
const MODELS := {
	"mushnub": "res://assets/models/creatures/mushnub.glb",
	"cactoro": "res://assets/models/creatures/cactoro.glb",
}
const GLOW_NAMES := ["NK_Cap", "NK_Band"]

@export_enum("mushnub", "cactoro") var species: String = "mushnub"
@export var follow_distance: float = 0.85
@export var side_distance: float = 1.05
@export var catchup: float = 4.5

var _tree: AnimationTree
var _playback: AnimationNodeStateMachinePlayback
var _clips := {}
var _state := ""
var _lock := 0.0
var _idle_time := 0.0
var _rng := RandomNumberGenerator.new()


func _enter_tree() -> void:
	add_to_group("companion")


var _built: bool = false


func _ready() -> void:
	if _built:
		return
	_built = true
	_rng.randomize()
	var packed := load(_model_path()) as PackedScene
	var root := get_node_or_null("VisualRoot") as Node3D
	var placeholder := get_node_or_null("VisualRoot/Placeholder")
	if packed == null or root == null:
		if root != null:
			ToonMaterial.apply_node(root)
		return
	var pivot := Node3D.new()
	pivot.name = "FacePivot"
	pivot.rotation.y = PI
	pivot.scale = Vector3.ONE * SCALE
	root.add_child(pivot)
	var visual := packed.instantiate()
	visual.name = species.capitalize()
	pivot.add_child(visual)
	_style(visual)
	var player := _find_animation_player(visual)
	_bind_tree(player)
	if placeholder is Node3D:
		(placeholder as Node3D).visible = false


func snap_to(body: Node3D) -> void:
	if body == null:
		return
	global_position = _destination(body)


func _process(delta: float) -> void:
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
	var moving := speed > 0.35 or global_position.distance_to(destination) > 0.55
	if moving:
		var travel := destination - global_position
		travel.y = 0.0
		if travel.length_squared() > 0.02:
			_turn_toward(global_position + travel.normalized())
	else:
		_turn_toward(body.global_position)
	_drive(delta, moving, speed, gap)


func _drive(delta: float, moving: bool, speed: float, gap: float) -> void:
	if _playback == null:
		return
	_lock = maxf(0.0, _lock - delta)
	if gap > 0.42 and _state != "Jump":
		_go("Jump", 0.42)
		return
	if _lock > 0.0:
		return
	if moving:
		_idle_time = 0.0
		_set_walk_scale(speed)
		_go("Walk")
		return
	_idle_time += delta
	if _state == "Idle" and _idle_time > _rng.randf_range(2.6, 4.4):
		_idle_time = 0.0
		var fidget := "Dance" if _rng.randf() < 0.45 else "Yes"
		_go(fidget, 0.7 if fidget == "Dance" else 0.95)
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


func _set_walk_scale(speed: float) -> void:
	var ratio := clampf(speed / 2.4, 0.7, 1.75)
	if _tree != null:
		_tree.set("parameters/Walk/timescale/scale", ratio)


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
	var flat := target - global_position
	flat.y = 0.0
	if flat.length_squared() < 0.02:
		return
	look_at(global_position + flat.normalized(), Vector3.UP)


func _model_path() -> String:
	if MODELS.has(species):
		return String(MODELS[species])
	species = "mushnub"
	return String(MODELS["mushnub"])


func _bind_tree(player: AnimationPlayer) -> void:
	if player == null:
		return
	for suffix in ["Idle", "Walk", "Jump", "Yes", "Dance"]:
		var clip_name := _find_clip(player, suffix)
		_clips[suffix] = clip_name
		if clip_name == StringName():
			continue
		var clip := player.get_animation(clip_name)
		if clip == null:
			continue
		clip.loop_mode = Animation.LOOP_LINEAR if suffix == "Idle" or suffix == "Walk" else Animation.LOOP_NONE
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
	_add_state(machine, "Idle", false)
	_add_state(machine, "Walk", true)
	_add_state(machine, "Jump", false)
	_add_state(machine, "Yes", false)
	_add_state(machine, "Dance", false)
	_link(machine, "Start", "Idle", 0.0, false)
	_link(machine, "Idle", "Walk", 0.15, false)
	_link(machine, "Walk", "Idle", 0.18, false)
	_link(machine, "Idle", "Jump", 0.05, false)
	_link(machine, "Walk", "Jump", 0.05, false)
	_link(machine, "Jump", "Idle", 0.1, true)
	_link(machine, "Idle", "Yes", 0.1, false)
	_link(machine, "Idle", "Dance", 0.1, false)
	_link(machine, "Yes", "Idle", 0.12, true)
	_link(machine, "Dance", "Idle", 0.12, true)
	_link(machine, "Yes", "Walk", 0.1, false)
	_link(machine, "Dance", "Walk", 0.1, false)
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
		var text := String(name)
		if text == suffix or text.ends_with("|" + suffix):
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
					mat.set_shader_parameter("emission_energy", maxf(energy, 1.5))
					mat.set_shader_parameter("emission_color", _emission_color(source))
				mesh_instance.set_surface_override_material(index, mat)
	for child in node.get_children():
		_style(child)


func _emission_color(source: Material) -> Color:
	if source is StandardMaterial3D:
		var standard := source as StandardMaterial3D
		var glow := maxf(standard.emission.r, maxf(standard.emission.g, standard.emission.b))
		if glow > 0.02:
			return standard.emission
		return standard.albedo_color
	return Color(0.45, 0.9, 0.75)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
