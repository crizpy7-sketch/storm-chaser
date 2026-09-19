shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float opacity=0.25;
uniform float warning=0.0;
void fragment(){
 vec2 p=UV*2.0-1.0;
 float d=length(p);
 float shade=1.0-smoothstep(0.28,1.0,d);
 float rim=(1.0-smoothstep(0.014,0.055,abs(d-0.77)))*warning;
 ALBEDO=mix(vec3(0.012,0.018,0.02),vec3(0.50,0.32,0.13),rim);
 ALPHA=max(shade*opacity,rim*0.24);
}
