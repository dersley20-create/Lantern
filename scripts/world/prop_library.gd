class_name PropLibrary
extends RefCounted

## Turns PropDef scenes into per-chunk MultiMeshes.
## A .glb with several MeshInstance3D children becomes one MultiMesh per child,
## so trunk and canopy keep their own materials. instance_as_scene stays a
## real node (used for Wellstones, which carry a collision shape).

var _defs: Dictionary = {}
var _parts: Dictionary = {}


func _init(cfg: WorldConfig) -> void:
	if cfg == null:
		return
	for biome in cfg.biomes:
		if biome == null:
			continue
		for prop in biome.props:
			if prop == null or String(prop.id).is_empty():
				continue
			_defs[String(prop.id)] = prop


func attach(parent: Node3D, transforms_by_id: Dictionary, chunk_size: float) -> void:
	for key in transforms_by_id.keys():
		var id := String(key)
		var xforms: Array = transforms_by_id[key]
		if xforms.is_empty():
			continue
		var prop: PropDef = _defs.get(id, null)
		if prop == null or prop.scene == null:
			continue
		if prop.instance_as_scene:
			_add_scenes(parent, prop, xforms)
		else:
			_add_multimeshes(parent, prop, xforms, chunk_size)


func _add_scenes(parent: Node3D, prop: PropDef, xforms: Array) -> void:
	for xf in xforms:
		var node := prop.scene.instantiate()
		_style_tree(node, prop)
		parent.add_child(node)
		node.transform = xf


func _add_multimeshes(parent: Node3D, prop: PropDef, xforms: Array, chunk_size: float) -> void:
	for part in _parts_for(prop):
		var mesh: Mesh = part.mesh
		if mesh == null:
			continue
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_colors = false
		multi.mesh = mesh
		multi.instance_count = xforms.size()
		multi.custom_aabb = AABB(Vector3(-2, -12, -2), Vector3(chunk_size + 4.0, 48.0, chunk_size + 4.0))
		var local: Transform3D = part.local
		for i in xforms.size():
			var scatter: Transform3D = xforms[i]
			multi.set_instance_transform(i, scatter * local)
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multi
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var material: Material = part.material
		if material != null:
			instance.material_override = material
		parent.add_child(instance)


func _parts_for(prop: PropDef) -> Array:
	var id := String(prop.id)
	if _parts.has(id):
		return _parts[id]
	var inst := prop.scene.instantiate()
	var parts: Array = []
	_collect(inst, Transform3D.IDENTITY, prop, parts)
	inst.free()
	_parts[id] = parts
	return parts


func _collect(node: Node, parent_xf: Transform3D, prop: PropDef, parts: Array) -> void:
	var xf: Transform3D = parent_xf
	if node is Node3D:
		xf = parent_xf * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			var source := mesh_instance.get_surface_override_material(0)
			if source == null and mesh_instance.mesh.get_surface_count() > 0:
				source = mesh_instance.mesh.surface_get_material(0)
			parts.append({
				"mesh": mesh_instance.mesh,
				"material": _style_material(source, prop, String(mesh_instance.name)),
				"local": xf,
			})
	for child in node.get_children():
		_collect(child, xf, prop, parts)


func _style_tree(node: Node, prop: PropDef) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			var surfaces := mesh_instance.mesh.get_surface_count()
			for surface_index in surfaces:
				var source := mesh_instance.get_surface_override_material(surface_index)
				if source == null:
					source = mesh_instance.mesh.surface_get_material(surface_index)
				var styled := _style_material(source, prop, String(mesh_instance.name))
				if styled != null:
					mesh_instance.set_surface_override_material(surface_index, styled)
	for child in node.get_children():
		_style_tree(child, prop)


func _style_material(source: Material, prop: PropDef, surface_name: String) -> Material:
	if source == null:
		var created := StandardMaterial3D.new()
		created.albedo_color = prop.tint
		created.roughness = 1.0
		created.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		return created
	var styled := source.duplicate()
	if styled is StandardMaterial3D:
		var material := styled as StandardMaterial3D
		var albedo := material.albedo_color
		material.albedo_color = Color(albedo.r * prop.tint.r, albedo.g * prop.tint.g, albedo.b * prop.tint.b, albedo.a)
		material.roughness = 1.0
		material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		if prop.override_emission and _emits(prop, surface_name):
			material.emission_enabled = prop.emission_energy > 0.001
			material.emission = prop.emission_color
			material.emission_energy_multiplier = prop.emission_energy
	return styled


func _emits(prop: PropDef, surface_name: String) -> bool:
	if prop.emission_surface_names.is_empty():
		return true
	return prop.emission_surface_names.has(surface_name)
