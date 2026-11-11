class_name ToonMaterial
extends RefCounted

## Builds the shared mobile cel material from a plain imported colour.

const SHADER_PATH := "res://assets/shaders/toon.gdshader"

static var _shader: Shader


static func shader() -> Shader:
	if _shader == null:
		_shader = load(SHADER_PATH) as Shader
	return _shader


static func from_source(source: Material, tint: Color = Color.WHITE, prop: PropDef = null, surface_name: String = "", wind: float = 0.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader()
	var albedo := Color.WHITE
	var emission := Color.BLACK
	var energy := 0.0
	if source is StandardMaterial3D:
		var standard := source as StandardMaterial3D
		albedo = standard.albedo_color
		if standard.emission_enabled:
			emission = standard.emission
			energy = standard.emission_energy_multiplier
	albedo = Color(albedo.r * tint.r, albedo.g * tint.g, albedo.b * tint.b, albedo.a)
	if prop != null and prop.override_emission and _emits(prop, surface_name):
		emission = prop.emission_color
		energy = prop.emission_energy
	material.set_shader_parameter("albedo_color", albedo)
	material.set_shader_parameter("use_vertex_color", false)
	material.set_shader_parameter("emission_color", emission)
	material.set_shader_parameter("emission_energy", energy)
	material.set_shader_parameter("rim_strength", 0.08 if energy > 0.2 else 0.28)
	material.set_shader_parameter("color_steps", 3.0)
	var sway := wind
	if prop != null:
		sway = prop.wind_strength
	material.set_shader_parameter("wind_strength", sway)
	return material


static func apply_node(root: Node, tint: Color = Color.WHITE, wind: float = 0.0) -> void:
	if root is MeshInstance3D:
		var mesh_instance := root as MeshInstance3D
		if mesh_instance.mesh != null:
			var surfaces := mesh_instance.mesh.get_surface_count()
			for surface_index in surfaces:
				var source := mesh_instance.get_surface_override_material(surface_index)
				if source == null:
					source = mesh_instance.mesh.surface_get_material(surface_index)
				mesh_instance.set_surface_override_material(surface_index, from_source(source, tint, null, "", wind))
	for child in root.get_children():
		apply_node(child, tint, wind)


static func _emits(prop: PropDef, surface_name: String) -> bool:
	if prop.emission_surface_names.is_empty():
		return true
	return prop.emission_surface_names.has(surface_name)
