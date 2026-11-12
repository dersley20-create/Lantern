shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always, cull_disabled, specular_disabled, ambient_light_disabled;

uniform vec4 shallow_color : source_color = vec4(0.22, 0.68, 0.66, 0.94);
uniform vec4 deep_color : source_color = vec4(0.10, 0.42, 0.55, 0.98);
uniform vec4 foam_color : source_color = vec4(0.93, 0.95, 0.9, 0.85);
uniform bool use_shore_foam = true;
uniform sampler2D depth_tex : hint_depth_texture, filter_linear, repeat_disable;

void vertex() {
	float wave = sin(VERTEX.x * 0.35 + TIME * 0.8) * 0.045 + cos(VERTEX.z * 0.28 + TIME * 0.55) * 0.03;
	VERTEX.y += wave;
}

void fragment() {
	float ripple = sin(UV.x * 40.0 + TIME * 0.7) * cos(UV.y * 36.0 - TIME * 0.5);
	vec3 water = mix(shallow_color.rgb, deep_color.rgb, 0.45 + ripple * 0.08);
	float alpha = mix(shallow_color.a, deep_color.a, 0.5);
	float foam = 0.0;
	if (use_shore_foam) {
		float depth = texture(depth_tex, SCREEN_UV).x;
		vec4 view_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
		view_pos.xyz /= view_pos.w;
		float scene_depth = -view_pos.z;
		float surface_depth = -VERTEX.z;
		float diff = scene_depth - surface_depth;
		foam = (1.0 - smoothstep(0.02, 1.6, diff)) * (0.55 + 0.45 * ripple);
		foam = clamp(foam, 0.0, 1.0);
	}
	ALBEDO = mix(water, foam_color.rgb, foam);
	ALPHA = mix(alpha, foam_color.a, foam);
}
