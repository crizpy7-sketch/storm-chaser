shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;

uniform sampler2D pose_atlas : source_color, filter_linear;
uniform vec2 pose_from = vec2(0.0, 0.0);
uniform vec2 pose_to = vec2(0.0, 0.0);
uniform float pose_blend : hint_range(0.0, 1.0) = 1.0;
uniform float lean = 0.0;
uniform float breath = 0.0;
uniform float camera_sweep = 0.0;
uniform float film_clock = 0.0;
uniform float storm_flash = 0.0;

vec4 cutout(vec2 cell, vec2 uv) {
	vec2 at = (clamp(uv, vec2(0.004), vec2(0.996)) + cell) * 0.5;
	vec4 ink = texture(pose_atlas, at);
	float green = ink.g - max(ink.r, ink.b);
	float matte = 1.0 - smoothstep(0.18, 0.43, green) * smoothstep(0.40, 0.85, ink.g);
	// Remove chroma spill only at the keyed edge; the teal shirt stays intact.
	ink.g = mix(min(ink.g, max(ink.r, ink.b) + 0.035), ink.g, step(0.985, matte));
	return vec4(ink.rgb * matte, matte);
}

void vertex() {
	float upper = 1.0 - smoothstep(0.28, 0.84, UV.y);
	float shoulders = 1.0 - smoothstep(0.22, 0.54, UV.y);
	VERTEX.x += lean * upper + camera_sweep * shoulders;
	VERTEX.y += breath * upper;
	VERTEX.z += abs(lean) * upper * 0.14;
}

void fragment() {
	vec4 ink = mix(cutout(pose_from, UV), cutout(pose_to, UV), pose_blend);
	if (ink.a < 0.20) { discard; }
	vec3 color = ink.rgb / max(ink.a, 0.001);
	float led = step(0.78, color.r) * (1.0-step(0.15, color.g)) * (1.0-step(0.18, color.b));
	color *= mix(1.0, 0.77 + 0.23 * sin(film_clock * 5.0), led);
	// Grade the actor after keying so the matte and teal clothing stay separate.
	// The original sunny-blue wardrobe needs less chroma than his skin and camera.
	float blue_cloth = smoothstep(0.03, 0.20, color.b - color.r)
		* smoothstep(0.01, 0.12, color.g - color.r);
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	vec3 graded = mix(vec3(luma), color, mix(0.60, 0.26, blue_cloth));
	// Cool overcast fill and the bed's soft lower-body shadow match the truck.
	float bed_shade = mix(1.0, 0.72, smoothstep(0.35, 0.85, UV.y));
	graded *= vec3(0.78, 0.90, 0.94) * 0.68 * bed_shade;
	graded += graded * vec3(0.20, 0.24, 0.28) * storm_flash;
	ALBEDO = graded;
	ALPHA = ink.a;
}
