shader_type canvas_item;
varying vec4 tint;
void vertex(){tint=COLOR;}
void fragment(){
 vec4 film=texture(TEXTURE,UV);
 vec3 grade=(film.rgb-vec3(0.5))*1.06+vec3(0.5);
 grade*=vec3(0.90,0.975,1.06);
 float lift=smoothstep(0.0,0.22,dot(grade,vec3(0.3,0.5,0.2)));
 grade=mix(grade*vec3(0.78,0.88,0.92),grade,lift);
 float vignette=1.0-dot(UV-vec2(0.5),UV-vec2(0.5))*0.22;
 COLOR=vec4(max(grade,vec3(0.0))*vignette,film.a)*tint;
}
