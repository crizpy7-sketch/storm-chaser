shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;

uniform sampler2D truck_art : source_color;
uniform sampler2D pose_art;
uniform bool pose_enabled=false;
uniform float pose_shift=0.0;
uniform vec4 storm_tint : source_color = vec4(0.82, 0.89, 0.93, 1.0);
uniform float damage = 0.0;
uniform float clock = 0.0;
uniform float braking = 0.0;
uniform float wheel_phase = 0.0;
uniform float wheel_motion = 0.0;
uniform float wheel_blur = 0.0;

// The tire silhouette and the complete truck alpha stay fixed. Only rubber
// below the bumper samples a moving, softly wrapped strip of its own tread.
vec3 tread_belt(vec2 uv, float phase) {
	float along = fract((uv.y - 0.84) * 8.0 + phase);
	float alternate = fract(along + 0.5);
	vec3 a = texture(truck_art, vec2(uv.x, 0.858 + along * 0.069)).rgb;
	vec3 b = texture(truck_art, vec2(uv.x, 0.858 + alternate * 0.069)).rgb;
	float seam = smoothstep(0.65, 1.0, abs(along * 2.0 - 1.0));
	return mix(a, b, seam);
}

vec3 rolling_tires(vec2 uv, vec3 original) {
	float center_x = uv.x < 0.5 ? 0.201 : 0.799;
	vec2 tire = vec2((uv.x - center_x) / 0.064, (uv.y - 0.855) / 0.090);
	float rubber = 1.0 - smoothstep(0.76, 1.0, length(tire));
	rubber *= smoothstep(0.833, 0.855, uv.y) * (1.0 - smoothstep(0.931, 0.942, uv.y));
	if (rubber * wheel_motion < 0.001) { return original; }
	vec3 moving = tread_belt(uv, wheel_phase) * 0.5;
	moving += tread_belt(uv, wheel_phase - wheel_blur) * 0.25;
	moving += tread_belt(uv, wheel_phase + wheel_blur) * 0.25;
	return mix(original, moving, rubber * wheel_motion);
}

float scratch(vec2 point, vec2 start, vec2 end) {
	vec2 path = end - start;
	float along = clamp(dot(point - start, path) / dot(path, path), 0.0, 1.0);
	return 1.0 - smoothstep(0.001, 0.003, length(point - start - path * along));
}

uniform float layer_min_v = 0.0;

void fragment() {
	if (UV.y < layer_min_v) { discard; }
	vec4 source = texture(truck_art, UV);
	if(pose_enabled){
        vec2 pose_uv=UV+vec2(pose_shift,0.0);
        source=texture(pose_art,clamp(pose_uv,vec2(0),vec2(1)));
        float key=min(source.r,source.b)-source.g;
        source.a=1.0-clamp(key,0.0,1.0);
        if(source.a<.06 || pose_uv.x<0.0 || pose_uv.x>1.0){discard;}
        source.rgb=clamp((source.rgb-vec3(1,0,1)*(1.0-source.a))/max(source.a,.06),vec3(0),vec3(1));
        if(!OUTPUT_IS_SRGB){source.rgb=mix(source.rgb/12.92,pow((source.rgb+vec3(.055))/1.055,vec3(2.4)),step(vec3(.04045),source.rgb));}
        float rubber=(1.0-smoothstep(.11,.24,max(source.r,max(source.g,source.b))))*smoothstep(.81,.86,UV.y)*(1.0-smoothstep(.94,.97,UV.y));
        source.rgb*=1.0-rubber*wheel_motion*(.08+.08*sin(UV.y*190.0+wheel_phase*6.283185));
    }
    vec3 color = (pose_enabled ? source.rgb : rolling_tires(UV, source.rgb)) * storm_tint.rgb;
	// Wear is painted over the tailgate; the original silhouette never deforms.
	float scars = scratch(UV, vec2(0.30, 0.645), vec2(0.42, 0.627)) * smoothstep(0.18, 0.35, damage);
	scars += scratch(UV, vec2(0.58, 0.699), vec2(0.69, 0.670)) * smoothstep(0.40, 0.58, damage);
	scars += scratch(UV, vec2(0.39, 0.712), vec2(0.53, 0.721)) * smoothstep(0.62, 0.80, damage);
	color = mix(color, vec3(0.10, 0.15, 0.16), clamp(scars * 0.8, 0.0, 0.8));
	float lamp_band = step(0.591, UV.y) * (1.0 - step(0.696, UV.y));
	float left_lamp = step(0.189, UV.x) * (1.0 - step(0.234, UV.x)) * lamp_band;
	float right_lamp = step(0.749, UV.x) * (1.0 - step(0.800, UV.x)) * lamp_band;
	float red_lens = smoothstep(0.04, 0.22, source.r - source.g);
	float flicker = step(0.48, damage) * step(-0.1, sin(clock * 23.0));
	color *= 1.0 - left_lamp * red_lens * flicker * 0.67;
	color += vec3(0.09, 0.006, 0.002) * (left_lamp + right_lamp) * red_lens * braking;
	ALBEDO = color;
	ALPHA = source.a;
}
