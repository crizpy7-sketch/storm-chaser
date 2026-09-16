shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D truck_art : source_color, filter_linear_mipmap;
uniform vec3 paint_tint = vec3(.78,.80,.83);
uniform float paint_roughness = .69;
uniform float paint_metallic = .13;
uniform float paint_clearcoat = 0.0;
uniform float damage = 0.0;
uniform float clock = 0.0;
varying vec3 body_position;
void vertex() {
	body_position = VERTEX;
}
void fragment() {
	vec3 paint = texture(truck_art, UV).rgb * paint_tint;
	float speck = fract(sin(dot(floor(body_position*145.0),vec3(12.9898,78.233,37.719)))*43758.5453);
	float chips = smoothstep(.84,.99,speck) * damage * .52;
	ALBEDO = mix(paint,vec3(.10,.085,.065),chips);
	ROUGHNESS = min(1.0, paint_roughness + damage*.17);
	METALLIC = paint_metallic * (1.0-chips);
	CLEARCOAT = paint_clearcoat;
	CLEARCOAT_ROUGHNESS = .25;
}
