shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 base_color : source_color = vec4(.26,.22,.16,1.0);
uniform float wood=0.0;
uniform float metal=.5;
uniform float flash=0.0;
uniform float wetness=0.4;
varying vec3 point;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){point=VERTEX;}
void fragment(){
 float dirt=noise(point*9.0)*.4+noise(point*35.0)*.18;
 float grain=noise(point*vec3(45.0,4.0,29.0));
 float seams=smoothstep(.03,.065,abs(fract(point.y*5.0)-.5));
 vec3 shade=base_color.rgb*(.60+dirt+grain*.23);
 shade*=mix(1.0,.42+.58*seams,wood);
 float chip=step(.84,noise(point*56.0));
 ALBEDO=mix(shade,vec3(.11,.15,.16),chip*(1.0-wood)*.45);
 ALBEDO*=1.0+flash*0.5;
 METALLIC=metal;
 ROUGHNESS=mix(.48+wood*.38+dirt*.15, .22, wetness*(1.0-wood));
 EMISSION=ALBEDO*flash*0.12;
}
