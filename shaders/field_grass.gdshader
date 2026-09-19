shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
#include "res://shaders/terrain_field.gdshaderinc"
uniform vec4 grass_color : source_color = vec4(0.333, 0.341, 0.22, 1.0);
uniform float clock = 0.0;
uniform float flash = 0.0;
varying float blade;
void vertex(){
 vec3 origin=MODEL_MATRIX[3].xyz;
 float h=max(VERTEX.y,0.0);
 VERTEX.x+=sin(clock*1.55+origin.x*0.21+origin.z*0.13)*h*0.22;
 VERTEX.z+=cos(clock*1.18+origin.z*0.17)*h*0.12;
 if(terrain_field){
  VERTEX+=inverse(mat3(MODEL_MATRIX))*vec3(0.0,field_height(origin.xz)-origin.y,0.0);
 }
 blade=fract(origin.x*12.9898+origin.z*78.233);
}
void fragment(){
 vec3 col=grass_color.rgb;
 col*=mix(0.72,1.18,blade);
 col=mix(col,vec3(.22,.24,.14),blade*0.35);
 ALBEDO=col*(1.0+flash*0.4);
 ROUGHNESS=.92;
 METALLIC=0.0;
 EMISSION=col*flash*0.08;
}
