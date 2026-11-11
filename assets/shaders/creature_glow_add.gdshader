shader_type spatial;
// Additive twinkle for seed glow and glimmer. Adapted from the artist's
// reference, without a vertex hook so the 16-bone skin still deforms.
render_mode unshaded, blend_add, cull_disabled, shadows_disabled, ambient_light_disabled;

uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform float base = 1.15;
uniform float amp = 0.45;
uniform float speed = 3.4;

void fragment() {
	float k = max(base + amp * sin(TIME * speed), 0.0);
	ALBEDO = glow_color.rgb * k;
}
