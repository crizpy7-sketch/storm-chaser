shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
// Roadside grass. In the hill levels each tuft sits on the shared elevation field
// evaluated at its instance origin, so it always matches the rendered terrain.
#include "res://shaders/terrain_field.gdshaderinc"
uniform vec4 grass_color : source_color = vec4(0.333, 0.341, 0.22, 1.0);
void vertex(){
 if(terrain_field){
  vec3 origin=MODEL_MATRIX[3].xyz;
  // Lift in world space, expressed in the tuft's rotated and scaled local space.
  VERTEX+=inverse(mat3(MODEL_MATRIX))*vec3(0.0,field_height(origin.xz)-origin.y,0.0);
 }
}
void fragment(){
 ALBEDO=grass_color.rgb;
 ROUGHNESS=.98;
 METALLIC=0.0;
}
