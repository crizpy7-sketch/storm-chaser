shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform sampler2D storm_sky : source_color;
uniform float clock = 0.0;
uniform float phase = 0.0;
uniform float mud = 0.0;
void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float angle = atan(p.y, p.x);
    float rim = 0.9 + sin(angle * 7.0 + phase) * 0.025 + sin(angle * 13.0) * 0.018;
    float d = length(p);
    float edge = 1.0 - smoothstep(rim - 0.07, rim, d);
    float rain = sin(p.x * 28.0 + clock * 6.4) * sin(p.y * 31.0 - clock * 5.1);
    float waves = sin(p.y * 52.0 + sin(p.x * 15.0 + phase) * 2.0 - clock * 8.0) + rain * 0.35;
    vec2 sky_uv = vec2(0.5 + p.x * 0.21, 0.25 + p.y * 0.19 + waves * 0.006);
    vec3 reflection = texture(storm_sky, sky_uv).rgb;
    float silver = pow(max(0.0, waves), 14.0) * 0.07;
    float bank = smoothstep(rim - 0.13, rim - 0.065, d) * 0.12;
    ALBEDO = reflection * 0.92 + vec3(0.035, 0.075, 0.086) + silver + bank * vec3(0.3, 0.47, 0.5);
    ALBEDO = mix(ALBEDO, reflection * 0.46 + vec3(0.21,0.14,0.081) + silver + bank * vec3(0.40,0.28,0.16), mud);
    ALPHA = edge * 0.9;
}
