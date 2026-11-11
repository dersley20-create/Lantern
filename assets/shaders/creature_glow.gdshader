shader_type spatial;
// Unshaded catchlight for eyes. No custom vertex(), so the skin stays intact.
render_mode unshaded, cull_back, shadows_disabled, ambient_light_disabled;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 0.96, 1.0);
uniform float base = 1.25;
uniform float amp = 0.08;
uniform float speed = 2.2;

void fragment() {
	float k = max(base + amp * sin(TIME * speed), 0.0);
	ALBEDO = glow_color.rgb * k;
}
