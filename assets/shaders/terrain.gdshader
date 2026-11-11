shader_type spatial;
// Lambert, no specular: cheap enough for the mobile renderer.
// Vertex alpha carries a small glow amount (glimmer), not transparency.
render_mode diffuse_lambert, specular_disabled, cull_disabled;

varying vec4 v_color;

void vertex() {
	v_color = COLOR;
}

void fragment() {
	ALBEDO = v_color.rgb;
	ROUGHNESS = 1.0;
	EMISSION = v_color.rgb * v_color.a;
}
