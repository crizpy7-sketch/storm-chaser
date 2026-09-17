shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled, blend_mix, depth_draw_never;
uniform float clock = 0.0;
uniform float density = 0.4;
uniform float wind = 0.0;
void fragment() {
	float drift = wind * 0.35;
	float x = UV.x * 52.0 + drift * UV.y;
	float y1 = fract(UV.y * 7.0 - clock * 1.85);
	float y2 = fract(UV.y * 11.0 - clock * 2.4 + UV.x * 3.0);
	float streak = smoothstep(0.018, 0.0, abs(fract(x) - 0.5));
	float streak2 = smoothstep(0.012, 0.0, abs(fract(x * 1.73 + 0.31) - 0.5));
	streak *= smoothstep(0.0, 0.12, y1) * smoothstep(1.0, 0.55, y1);
	streak2 *= smoothstep(0.0, 0.18, y2) * smoothstep(1.0, 0.4, y2);
	float mist = 0.04 + 0.03 * sin(UV.x * 18.0 + clock * 0.7);
	float fade = smoothstep(0.0, 0.08, UV.y) * smoothstep(1.0, 0.72, UV.y);
	ALBEDO = vec3(0.58, 0.70, 0.76);
	ALPHA = clamp((streak * 0.55 + streak2 * 0.35 + mist) * density * fade, 0.0, 0.45);
}
