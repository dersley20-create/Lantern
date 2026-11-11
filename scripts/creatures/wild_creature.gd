class_name WildCreature
extends Node3D

## A wild Nestkin. Idle, then a short walk, then idle again, with the odd
## Yes, Dance, or Jump. They drift away if you get close. Past about 30 m
## the brain and the clip pause so a phone is not skinning the whole herd.

const SCALE := 0.33
const AWAKE_DISTANCE := 30.0
const PERSONAL_SPACE := 4.2
const WALK_SPEED := 1.12
const AWAY_SPEED := 1.45
const LEASH := 6.5

var species: StringName = &"cactoro"
var home := Vector3.ZERO

var _rng := RandomNumberGenerator.new()
var _anim: AnimationPlayer
var _clips := {}
var _state := 0
var _timer := 0.0
var _target := Vector3.ZERO
var _frozen := true
var _clip := ""

const _IDLE := 0
const _WALK := 1
const _FIDGET := 2
const _HOP := 3


static func attach(chunk: Node3D, params: TerrainParams, noises: Dictionary) -> void:
	var spots: Array = WildSpawn.plan(params, noises, chunk.position.x, chunk.position.z, chunk.coord)
	for spot in spots:
		var creature := WildCreature.new()
		creature.name = String(spot.species)
		creature.species = spot.species
		var y := TerrainSampler.height_at(params, noises, float(spot.x), float(spot.z))
		creature.position = Vector3(float(spot.x) - chunk.position.x, y, float(spot.z) - chunk.position.z)
		creature.home = creature.position
		creature._rng.seed = int(spot.seed)
		chunk.add_child(creature)


func _ready() -> void:
	add_to_group("wild_creature")
	var packed := _scene(species)
	if packed == null:
		return
	var pivot := Node3D.new()
	pivot.name = "FacePivot"
	# The mesh faces +Z. look_at aims -Z, so the visual turns around.
	pivot.rotation.y = PI
	pivot.scale = Vector3.ONE * SCALE
	add_child(pivot)
	var visual := packed.instantiate()
	visual.name = "Visual"
	pivot.add_child(visual)
	_style(visual)
	_anim = _find_player(visual)
	_bind_clips()
	_enter_idle()


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	if global_position.distance_squared_to(player.global_position) > AWAKE_DISTANCE * AWAKE_DISTANCE:
		_pause()
		return
	if _frozen:
		_frozen = false
		_play(_clip if _clip != "" else "Idle", _state == _WALK)
	_tick(delta, player.global_position)


func _tick(delta: float, player_pos: Vector3) -> void:
	var crowded := _flat_distance(player_pos) < PERSONAL_SPACE
	_timer -= delta
	match _state:
		_IDLE:
			if crowded or _timer <= 0.0:
				_leave_idle(player_pos, crowded)
		_WALK:
			if crowded and _target_nears(player_pos):
				_aim_away(player_pos)
			_step_toward(delta, AWAY_SPEED if crowded else WALK_SPEED)
			if _flat_distance_to(_target) < 0.4 or _timer <= 0.0:
				_enter_idle()
		_HOP:
			_step_toward(delta, WALK_SPEED * 0.85)
			if _timer <= 0.0:
				_enter_idle()
		_FIDGET:
			if _timer <= 0.0:
				_enter_idle()
	_plant_feet()


func _leave_idle(player_pos: Vector3, crowded: bool) -> void:
	var roll := _rng.randf()
	if crowded or roll < 0.62:
		_begin_walk(player_pos, crowded)
	elif roll < 0.82:
		_begin_fidget()
	else:
		_begin_hop(player_pos, crowded)


func _begin_walk(player_pos: Vector3, crowded: bool) -> void:
	_state = _WALK
	_timer = _rng.randf_range(2.2, 4.4)
	if crowded:
		_aim_away(player_pos)
	else:
		_pick_nearby()
	_play("Walk", true)
	_face(_target)


func _begin_fidget() -> void:
	_state = _FIDGET
	var clip := "Dance" if _rng.randf() < 0.5 else "Yes"
	_timer = 1.05 if clip == "Yes" else 0.75
	_play(clip, false)


func _begin_hop(player_pos: Vector3, crowded: bool) -> void:
	_state = _HOP
	_timer = 0.42
	if crowded:
		_aim_away(player_pos)
		_target = position + (_target - position).limit_length(1.3)
	else:
		var yaw := _rng.randf() * TAU
		_target = position + Vector3(cos(yaw), 0.0, sin(yaw)) * _rng.randf_range(0.6, 1.2)
		_target = _clamp_leash(_target)
	_play("Jump", false)
	_face(_target)


func _enter_idle() -> void:
	_state = _IDLE
	_timer = _rng.randf_range(1.5, 3.3)
	_play("Idle", true)


func _pick_nearby() -> void:
	var yaw := _rng.randf() * TAU
	var dist := _rng.randf_range(2.2, 5.2)
	_target = _clamp_leash(home + Vector3(cos(yaw), 0.0, sin(yaw)) * dist)


func _target_nears(player_pos: Vector3) -> bool:
	var world_target := global_position + (_target - position)
	return world_target.distance_squared_to(player_pos) + 0.8 < global_position.distance_squared_to(player_pos)


func _aim_away(player_pos: Vector3) -> void:
	var away := global_position - player_pos
	away.y = 0.0
	if away.length_squared() < 0.04:
		away = Vector3(_rng.randf_range(-1.0, 1.0), 0.0, 1.0)
	away = away.normalized()
	var world_target := global_position + away * _rng.randf_range(3.2, 5.0)
	_target = _clamp_leash(world_target - global_position + position)


func _clamp_leash(point: Vector3) -> Vector3:
	var offset := point - home
	offset.y = 0.0
	if offset.length() > LEASH:
		offset = offset.normalized() * LEASH
	return home + offset


func _step_toward(delta: float, speed: float) -> void:
	var flat := _target - position
	flat.y = 0.0
	var step := speed * delta
	if flat.length() <= step:
		position.x = _target.x
		position.z = _target.z
	else:
		var dir := flat.normalized()
		position.x += dir.x * step
		position.z += dir.z * step
	_face(_target)


func _face(point: Vector3) -> void:
	var flat := point - position
	flat.y = 0.0
	if flat.length_squared() < 0.01:
		return
	look_at(global_position + flat.normalized(), Vector3.UP)


func _plant_feet() -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world == null or not world.has_method("sample_height"):
		return
	position.y = world.sample_height(global_position.x, global_position.z)


func _flat_distance(world_point: Vector3) -> float:
	var flat := global_position - world_point
	flat.y = 0.0
	return flat.length()


func _flat_distance_to(local_point: Vector3) -> float:
	var flat := position - local_point
	flat.y = 0.0
	return flat.length()


func _pause() -> void:
	if _frozen:
		return
	_frozen = true
	if _anim != null:
		_anim.pause()


func _play(suffix: String, looping: bool) -> void:
	_clip = suffix
	if _anim == null or not _clips.has(suffix):
		return
	var name: StringName = _clips[suffix]
	if name == StringName():
		return
	if _anim.current_animation == String(name) and _anim.is_playing():
		return
	_anim.play(name)
	if not looping:
		_anim.speed_scale = 1.0


func _bind_clips() -> void:
	if _anim == null:
		return
	for suffix in ["Idle", "Walk", "Jump", "Yes", "Dance"]:
		var name := _find_clip(suffix)
		_clips[suffix] = name
		if name == StringName():
			continue
		var clip := _anim.get_animation(name)
		if clip == null:
			continue
		clip.loop_mode = Animation.LOOP_LINEAR if suffix == "Idle" or suffix == "Walk" else Animation.LOOP_NONE


func _find_clip(suffix: String) -> StringName:
	if _anim == null:
		return StringName()
	for name in _anim.get_animation_list():
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
				mesh_instance.set_surface_override_material(index, ToonMaterial.from_source(source))
				mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		_style(child)


static func _scene(species: StringName) -> PackedScene:
	return load("res://assets/models/creatures/%s.glb" % String(species)) as PackedScene


func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null
