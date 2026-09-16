shader_type spatial;
render_mode cull_disabled;
uniform sampler2D rear_art : source_color;
uniform float damage=0.0;
varying float dent;
void vertex(){
 vec2 p=UV;
 dent=exp(-dot((p-vec2(0.26,0.62))*vec2(8.0,6.0),(p-vec2(0.26,0.62))*vec2(8.0,6.0)));
 dent+=exp(-dot((p-vec2(0.73,0.40))*vec2(9.0,8.0),(p-vec2(0.73,0.40))*vec2(9.0,8.0)))*0.75;
 VERTEX.z-=dent*damage*0.045;
}
void fragment(){
 vec3 art=texture(rear_art,vec2(0.248,0.579)+UV*vec2(0.500,0.163)).rgb;
 ALBEDO=art*vec3(0.72,0.79,0.83)*(1.0-damage*dent*0.38);
 ROUGHNESS=0.51; METALLIC=0.25;
}
