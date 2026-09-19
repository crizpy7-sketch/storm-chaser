shader_type spatial;
render_mode cull_disabled;
uniform vec4 paint : source_color = vec4(0.62, 0.27, 0.045, 1.0);
uniform float metal = 0.3;
uniform float rough = 0.48;
uniform float damage = 0.0;
uniform float bodywork = 0.0;
uniform sampler2D rear_art : source_color;
varying vec3 point;
varying vec3 face_normal;
float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1,311.7,74.7))) * 43758.5453); }
float noise(vec3 p) {
 vec3 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() { point=VERTEX; face_normal=NORMAL; }
void fragment() {
 float grain=noise(point*43.0);
 float mud=(1.0-smoothstep(0.7,1.6,point.y))*smoothstep(0.22,0.7,noise(point*12.0));
 float chips=smoothstep(0.72,0.86,noise(point*67.0)) * bodywork;
 vec3 color=paint.rgb*(0.83+grain*0.23);
 if (bodywork>0.5) {
  vec2 worn_uv=vec2(fract(point.z*0.44+point.x*0.31),fract(point.y*0.9));
  color=texture(rear_art,vec2(0.269,0.645)+worn_uv*vec2(0.18,0.025)).rgb*vec3(0.65,0.72,0.76);
 }
 // Original painted tailgate detail is mapped onto the rigid rear panel only.
 if (bodywork>0.5 && face_normal.z>0.8 && point.z>2.57 && abs(point.x)<0.88 && point.y>1.10 && point.y<1.88) {
  vec2 panel_uv=vec2((point.x+0.88)/1.76, (1.88-point.y)/0.78);
  color=texture(rear_art,vec2(0.248,0.579)+panel_uv*vec2(0.500,0.163)).rgb*vec3(0.72,0.79,0.83);
 }
 color=mix(color,vec3(0.09,0.12,0.12),chips*(0.15+damage*0.2));
 color=mix(color,vec3(0.12,0.13,0.115),mud*(0.25+damage*0.27));
 float scrape=smoothstep(0.63,0.79,noise(point*vec3(4.0,54.0,16.0)))*damage*bodywork;
 ALBEDO=mix(color,vec3(0.18,0.22,0.23),scrape*0.6);
 METALLIC=metal;
 ROUGHNESS=clamp(rough+mud*0.2+chips*0.25,0.0,1.0);
 SPECULAR=0.38;
}
