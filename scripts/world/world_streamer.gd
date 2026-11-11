class_name WorldStreamer
extends Node3D

## Streams a seeded heightfield around the player.
## The ring underfoot is built immediately so the body never falls through.
## Farther chunks are meshed on worker threads and applied a few per frame.
## Distant chunks use a coarser grid and skip props.

const CONFIG_PATH := "res://resources/world/world_config.tres"
const TERRAIN_SHADER := "res://assets/shaders/terrain.gdshader"

@export var config: WorldConfig

var spawn_position: Vector3 = Vector3(0, 4, 0)
var home_ready: bool = false

var _params: TerrainParams
var _noises: Dictionary = {}
var _library: PropLibrary
var _terrain_material: ShaderMaterial
var _chunks: Dictionary = {}
var _wanted: Dictionary = {}
var _inflight: Dictionary = {}
var _pending: Array = []
var _results: Array = []
var _mutex := Mutex.new()
var _jobs: int = 0
var _center := Vector2i.ZERO


func _enter_tree() -> void:
	add_to_group("world")


func _ready() -> void:
	if config == null:
		config = load(CONFIG_PATH) as WorldConfig
	if config == null:
		push_error("Lantern could not load WorldConfig at %s" % CONFIG_PATH)
		return
	_params = TerrainParams.from_config(config)
	_noises = TerrainSampler.create_noises(_params)
	_library = PropLibrary.new(config)
	_terrain_material = ShaderMaterial.new()
	_terrain_material.shader = load(TERRAIN_SHADER) as Shader
	spawn_position = TerrainSampler.find_spawn(_params, _noises)
	_center = TerrainSampler.chunk_coord(spawn_position.x, spawn_position.z, _params.chunk_size)
	_rebuild_wanted()
	_build_home_sync()
	var sample := TerrainSampler.sample_at(_params, _noises, spawn_position.x, spawn_position.z)
	print("Lantern world=%s seed=%s spawn=%s biome=%s" % [_params.world_name, _params.world_seed, spawn_position, sample.biome])


func sample_height(x: float, z: float) -> float:
	if _params == null or _noises.is_empty():
		return 0.0
	return TerrainSampler.height_at(_params, _noises, x, z)


func is_ring_ready() -> bool:
	if _wanted.is_empty():
		return false
	for coord in _wanted.keys():
		var want: Dictionary = _wanted[coord]
		if not _chunks.has(coord):
			return false
		var chunk: TerrainChunk = _chunks[coord]
		if chunk.lod != int(want.lod) or chunk.has_props != bool(want.props):
			return false
	return true


func _process(_delta: float) -> void:
	if _params == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		var coord := TerrainSampler.chunk_coord(player.global_position.x, player.global_position.z, _params.chunk_size)
		if coord != _center:
			_center = coord
			_rebuild_wanted()
	_enqueue()
	_collect()
	_apply_budget()
	_unload()


func _rebuild_wanted() -> void:
	_wanted.clear()
	var radius := maxi(_params.load_radius, 1)
	for dz in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var coord := Vector2i(_center.x + dx, _center.y + dz)
			var dist := _chebyshev(coord, _center)
			var lod := 0 if dist < _params.lod1_distance else 1
			var with_props := lod == 0 and dist <= _params.prop_radius
			_wanted[coord] = {"lod": lod, "props": with_props}


func _build_home_sync() -> void:
	for coord in _wanted.keys():
		if _chebyshev(coord, _center) > 1:
			continue
		var want: Dictionary = _wanted[coord]
		var data := ChunkMesher.build(_params, _noises, coord, int(want.lod), bool(want.props))
		_apply(data, false)
	home_ready = true


func _enqueue() -> void:
	var limit := maxi(_params.max_concurrent_jobs, 1)
	while _jobs < limit:
		var coord = _next_missing()
		if coord == null:
			return
		var want: Dictionary = _wanted[coord]
		var lod := int(want.lod)
		var with_props := bool(want.props)
		var job_params := _params.fork()
		var noises := TerrainSampler.create_noises(job_params)
		_inflight[coord] = true
		_jobs += 1
		WorldStreamer._submit(job_params, noises, coord, lod, with_props, _mutex, _results)


static func _submit(params: TerrainParams, noises: Dictionary, coord: Vector2i, lod: int, with_props: bool, mutex: Mutex, results: Array) -> void:
	WorkerThreadPool.add_task(_build_job.bind(params, noises, coord, lod, with_props, mutex, results))


static func _build_job(params: TerrainParams, noises: Dictionary, coord: Vector2i, lod: int, with_props: bool, mutex: Mutex, results: Array) -> void:
	var data := ChunkMesher.build(params, noises, coord, lod, with_props)
	mutex.lock()
	results.append(data)
	mutex.unlock()


func _next_missing() -> Variant:
	var best := Vector2i.ZERO
	var found := false
	var best_dist := 1 << 30
	for coord in _wanted.keys():
		if _inflight.has(coord):
			continue
		var want: Dictionary = _wanted[coord]
		if _chunks.has(coord):
			var chunk: TerrainChunk = _chunks[coord]
			if chunk.lod == int(want.lod) and chunk.has_props == bool(want.props):
				continue
		var dist := _chebyshev(coord, _center)
		if not found or dist < best_dist:
			found = true
			best = coord
			best_dist = dist
	return best if found else null


func _collect() -> void:
	var ready: Array = []
	_mutex.lock()
	ready = _results.duplicate()
	_results.clear()
	_mutex.unlock()
	if ready.is_empty():
		return
	_jobs = maxi(_jobs - ready.size(), 0)
	_pending.append_array(ready)


func _apply_budget() -> void:
	var budget := maxi(_params.max_applies_per_frame, 1)
	while budget > 0 and not _pending.is_empty():
		budget -= 1
		_apply(_pending.pop_front(), true)


func _apply(data: Dictionary, from_job: bool) -> void:
	var coord: Vector2i = data.coord
	if from_job:
		_inflight.erase(coord)
	if not _wanted.has(coord):
		return
	var want: Dictionary = _wanted[coord]
	if int(want.lod) != int(data.lod) or bool(want.props) != bool(data.with_props):
		return
	if _chunks.has(coord):
		var previous: Node = _chunks[coord]
		_chunks.erase(coord)
		previous.queue_free()
	var chunk := _make_chunk(data)
	_chunks[coord] = chunk
	add_child(chunk)


func _make_chunk(data: Dictionary) -> TerrainChunk:
	var chunk := TerrainChunk.new()
	chunk.name = "Chunk_%d_%d" % [int(data.coord.x), int(data.coord.y)]
	chunk.coord = data.coord
	chunk.lod = int(data.lod)
	chunk.has_props = bool(data.with_props)
	chunk.position = Vector3(float(data.origin_x), 0.0, float(data.origin_z))

	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = data.vertices
	arrays[Mesh.ARRAY_NORMAL] = data.normals
	arrays[Mesh.ARRAY_COLOR] = data.colors
	arrays[Mesh.ARRAY_INDEX] = data.indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _terrain_material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(visual)

	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(data.faces)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	chunk.add_child(body)

	if bool(data.with_props) and data.props is Dictionary:
		_library.attach(chunk, data.props, _params.chunk_size)
	return chunk


func _unload() -> void:
	var doomed: Array[Vector2i] = []
	for coord in _chunks.keys():
		if _chebyshev(coord, _center) > _params.unload_radius:
			doomed.append(coord)
	for coord in doomed:
		var node: Node = _chunks[coord]
		_chunks.erase(coord)
		_inflight.erase(coord)
		node.queue_free()


func _chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))
