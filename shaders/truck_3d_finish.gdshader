shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D truck_art : source_color, filter_linear_mipmap;
uniform vec3 paint_tint = vec3(.78,.80,.83);
uniform float paint_roughness = .69;
uniform float paint_metallic = .13;
uniform float paint_clearcoat = 0.0;
uniform float damage = 0.0;
uniform float clock = 0.0;
uniform float wetness = 0.55;
uniform float flash = 0.0;
varying vec3 body_position;
varying vec3 world_normal;
void vertex() {
	body_position = VERTEX;
	world_normal = (MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 paint = texture(truck_art, UV).rgb * paint_tint;
	float speck = fract(sin(dot(floor(body_position*145.0),vec3(12.9898,78.233,37.719)))*43758.5453);
	float chips = smoothstep(.84,.99,speck) * damage * .52;
	ALBEDO = mix(paint,vec3(.10,.085,.065),chips);
	float beads = pow(max(0.0, sin(body_position.y*42.0 + body_position.x*18.0 - clock*1.6)), 16.0);
	beads *= wetness * (1.0 - chips);
	ALBEDO += vec3(0.07, 0.09, 0.10) * beads;
	ALBEDO *= 1.0 + flash * 0.45;
	ROUGHNESS = min(1.0, mix(paint_roughness, paint_roughness * 0.42, wetness) + damage*.17 - beads*0.3);
	METALLIC = mix(paint_metallic, max(paint_metallic, paint_clearcoat * 0.35), wetness) * (1.0-chips);
	SPECULAR = mix(0.5, 0.84, wetness);
	EMISSION = ALBEDO * flash * 0.18;
	// Cool storm fill on the sky-facing panels so the cab reads under overcast.
	float up = clamp(world_normal.y, 0.0, 1.0);
	EMISSION += vec3(0.02, 0.035, 0.045) * up * 0.18;
	// Compatibility has no clearcoat; a facing sheen sells the wet paint.
	float sheen = pow(clamp(dot(normalize(world_normal), vec3(0.18, 0.84, 0.32)), 0.0, 1.0), 5.0);
	EMISSION += vec3(0.07, 0.08, 0.09) * sheen * wetness * 0.4;
}
