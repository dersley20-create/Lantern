shader_type spatial;
// Soft disc for the shoreline ribbon. Unshaded so it stays white in any light.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, ambient_light_disabled;

uniform vec4 albedo_color : source_color = vec4(0.96, 0.98, 0.95, 0.88);

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float soft = 1.0 - smoothstep(0.2, 1.0, dot(p, p));
	if (soft < 0.02) {
		discard;
	}
	ALBEDO = albedo_color.rgb;
	ALPHA = albedo_color.a * soft;
}
