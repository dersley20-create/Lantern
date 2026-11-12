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
uniform float wind_strength = 0.0;
uniform float light_neutral : hint_range(0.0, 1.0) = 0.0;
global uniform vec3 occluder_player;
global uniform vec3 occluder_camera;

void vertex() {
	// Uniform branch stays off for characters and rocks. Foliage sets wind_strength.
	if (wind_strength > 0.001) {
		float mask = clamp(VERTEX.y * 0.45, 0.0, 1.0);
		float phase = TIME * 1.35 + (MODEL_MATRIX[3].x + MODEL_MATRIX[3].z) * 0.37;
		float sway = sin(phase) * wind_strength * mask;
		VERTEX.x += sway;
		VERTEX.z += cos(phase * 0.8) * sway * 0.4;
	}
}

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
	// Screen-door cutaway so the player stays readable behind a cottage or a tree.
	// Stays in the opaque pass, which is cheaper than real transparency on a phone.
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 segment = occluder_player - occluder_camera;
	float segment_len2 = max(dot(segment, segment), 0.001);
	float along = clamp(dot(world_pos - occluder_camera, segment) / segment_len2, 0.0, 1.0);
	float off_axis = length(world_pos - (occluder_camera + segment * along));
	float above = world_pos.y - occluder_player.y;
	if (along > 0.12 && along < 0.9 && above > 0.25 && off_axis < 1.15) {
		// Solid cutaway in the middle, a short dither only on the rim.
		if (off_axis < 0.62) {
			discard;
		} else {
			float fade = smoothstep(1.15, 0.62, off_axis);
			float dither = fract(sin(dot(floor(world_pos.xz * 12.0), vec2(12.9898, 78.233))) * 43758.5453);
			if (dither < fade) {
				discard;
			}
		}
	}
}

void light() {
	float wrapped = clamp(dot(NORMAL, LIGHT) * (1.0 - wrap) + wrap, 0.0, 1.0);
	float bands = max(color_steps, 2.0);
	float stepped = floor(wrapped * bands) / (bands - 1.0);
	float lit = mix(min_light, 1.0, clamp(stepped, 0.0, 1.0));
	vec3 grade = mix(shadow_tint, vec3(1.0), lit);
	float peak = max(LIGHT_COLOR.r, max(LIGHT_COLOR.g, LIGHT_COLOR.b));
	vec3 tint = mix(LIGHT_COLOR, vec3(peak), light_neutral);
	DIFFUSE_LIGHT += ALBEDO * grade * ATTENUATION * tint * 0.75;
}
