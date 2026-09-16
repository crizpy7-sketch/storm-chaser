shader_type canvas_item;
varying vec4 tint;
void vertex(){tint=COLOR;}
void fragment(){
 vec4 film=texture(TEXTURE,UV);
 vec3 grade=(film.rgb-vec3(0.5))*1.025+vec3(0.5);
 grade*=vec3(0.94,0.985,1.0);
 float vignette=1.0-dot(UV-vec2(0.5),UV-vec2(0.5))*0.15;
 COLOR=vec4(max(grade,vec3(0.0))*vignette,film.a)*tint;
}
