shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float opacity = 0.0;
uniform float clock = 0.0;
uniform vec3 tint : source_color = vec3(0.28,0.30,0.29);
float noise(vec2 p) {
    return sin(p.x*6.9+sin(p.y*7.3))*sin(p.y*8.2+sin(p.x*5.6))*0.5+0.5;
}
void fragment() {
    vec2 p=UV*2.0-1.0;
    float edge=1.0-smoothstep(0.16,1.0,length(p));
    float n=noise(p*2.0+vec2(clock*0.09,clock*0.13));
    float billow=mix(n,noise(p*4.5-clock*0.07),0.32);
    ALBEDO=tint*mix(0.67,1.2,billow);
    ALPHA=edge*opacity*mix(0.22,0.80,billow);
}
