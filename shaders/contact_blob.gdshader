shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled, depth_draw_opaque, blend_mix, cull_disabled;
uniform float opacity = 0.34;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float a = (1.0 - smoothstep(0.12, 1.0, d));
	a *= a;
	ALBEDO = vec3(0.016, 0.022, 0.02);
	ALPHA = a * opacity;
}
