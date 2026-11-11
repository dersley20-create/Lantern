shader_type spatial;
// One-pass cel look for the mobile renderer: quantized Lambert, a cool
// shadow tint, and a fresnel rim instead of a second outline mesh.
render_mode diffuse_lambert, specular_disabled, cull_back, ambient_light_disabled;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform bool use_vertex_color = false;
uniform float color_steps : hint_range(2.0, 5.0) = 3.0;
uniform float wrap : hint_range(0.0, 0.8) = 0.22;
uniform float min_light : hint_range(0.0, 1.0) = 0.34;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.28;
uniform vec4 rim_color : source_color = vec4(1.0, 0.96, 0.88, 1.0);
uniform vec4 emission_color : source_color = vec4(0.0);
uniform float emission_energy = 0.0;
uniform vec3 shadow_tint = vec3(0.70, 0.74, 0.84);
uniform float ambient_level = 0.36;

void fragment() {
	vec3 base = albedo_color.rgb;
	if (use_vertex_color) {
		base *= COLOR.rgb;
	}
	ALBEDO = base;
	ROUGHNESS = 1.0;
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - facing, 2.4) * rim_strength;
	EMISSION = emission_color.rgb * emission_energy + ALBEDO * (rim * rim_color.rgb + ambient_level);
}

void light() {
	float wrapped = clamp(dot(NORMAL, LIGHT) * (1.0 - wrap) + wrap, 0.0, 1.0);
	float bands = max(color_steps, 2.0);
	float stepped = floor(wrapped * bands) / (bands - 1.0);
	float lit = mix(min_light, 1.0, clamp(stepped, 0.0, 1.0));
	vec3 grade = mix(shadow_tint, vec3(1.0), lit);
	DIFFUSE_LIGHT += ALBEDO * grade * ATTENUATION * LIGHT_COLOR * 0.75;
}
