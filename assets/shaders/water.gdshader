shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always, cull_disabled, specular_disabled;

uniform vec4 water_color : source_color = vec4(0.42, 0.66, 0.68, 0.46);

void fragment() {
	ALBEDO = water_color.rgb;
	ALPHA = water_color.a;
}
