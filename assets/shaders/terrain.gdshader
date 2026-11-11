shader_type spatial;
// Same cel model as toon.gdshader, with backfaces kept so chunk skirts stay visible.
render_mode diffuse_lambert, specular_disabled, cull_disabled, ambient_light_disabled;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform bool use_vertex_color = true;
uniform float color_steps : hint_range(2.0, 5.0) = 3.0;
uniform float wrap : hint_range(0.0, 0.8) = 0.28;
uniform float min_light : hint_range(0.0, 1.0) = 0.32;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.04;
uniform vec4 rim_color : source_color = vec4(1.0, 0.96, 0.88, 1.0);
uniform vec4 emission_color : source_color = vec4(0.0);
uniform float emission_energy = 0.0;
uniform vec3 shadow_tint = vec3(0.74, 0.76, 0.70);
uniform float ambient_level = 0.12;

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
	if (use_vertex_color) {
		EMISSION += base * COLOR.a;
	}
}

void light() {
	// One soft terminator. Hard bands on a gentle slope turn into stripes.
	float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float band = smoothstep(0.22, 0.62, ndotl);
	float lit = mix(min_light, 1.0, band);
	vec3 grade = mix(shadow_tint, vec3(1.0), lit);
	// Keep the ground's own colour. A warm sun still tints, but grass stays green.
	float peak = max(LIGHT_COLOR.r, max(LIGHT_COLOR.g, LIGHT_COLOR.b));
	vec3 tint = mix(LIGHT_COLOR, vec3(peak), 0.55);
	DIFFUSE_LIGHT += ALBEDO * grade * ATTENUATION * tint * 0.55;
}
